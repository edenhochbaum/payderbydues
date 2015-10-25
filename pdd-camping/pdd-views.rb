
module PayDerbyDues::Views
  def membertable
    table do
      thead do
        th "Derby name"
        th "Legal name"
        th "Dues due"
        th "add a charge"
      end
      tbody do
        @members.each do |member|
          tr do
            td member['derbyname']
            td member['legalname']
            pastdue, due = $pdd.dues_due(member['id']) #XXX: to controller/data layer
            td format_money(due)
            td do
              a "Add a charge",
                :href => R(UserCharge, @leagueid, member['memberid'])
            end
          end
        end
      end
    end
  end

  def leaguedashboard
    h2 "League members:"
    membertable
    a "Add members", :href => R(LeagueNAdduser, @leagueid)
    h2 "League account information"
    form :method => 'POST', :action => R(LeagueN, @leagueid) do
      # TODO: we want some javascript to only post stuff that was touched
      # TODO: add crudupdate stuffs here.
    end
  end

  def navbar
    nav do
      span :class => 'navitem' do
        a @leaguename, :href => R(LeagueN, @leagueid)
      end
      span :class => 'navitem' do
        a "#{@memberinfo['derbyname']} (#{@memberinfo['legalname']})",
          :href => R(User, @leagueid)
      end
      # span :class => 'navitem' { a "Profile", :href => R(Profile, @leagueid)}
      if @admin
        span :class => 'navitem' do
          a "League Admin", :href => R(LeagueAdmin, @leagueid)
        end
      end
      span :class => 'navitem navright' do
        a "Logout", :href => R(Logout)
      end
    end
  end
  def loginform
    if @info
      div @info, :class => 'error'
    end
    form :method => 'POST', :action => R(Login) do
      div do 
        label do
          text "Email:"
          input :name => 'username'
        end
      end
      div do 
        label do
          text "Password:"
          input :name => 'password', :type => 'password'
        end
      end
      button "Log in", :type => 'submit'
    end
  end
  def usercharge
    h2 "Charge/Credit " + @memberinfo['legalname']
    if @charge_amount
      div "Charge created for #{format_money(@charge_amount)}",
          :class => success
    end
    form :method => 'POST', :action => R(UserCharge, @leagueid, @memberid) do
      div do
        text "Amount: $"
        input :name => 'amount'
      end
      div do
        text "Description"
        input :name => 'description'
      end
      div do
        select :name => 'type' do
          option "Charge", :value => 'charge'
          option "Credit", :value => 'credit'
        end
      end
      button "Create Charge", :type => 'submit'
    end
    paymenthistory(@historyitems)
  end

  def paymenthistory(history)
    table do
      thead do
        th "Date"
        th "Charge amount"
        th "Credit amount"
        th "Description"
      end
      history.each do |item|
        tr do
          td item['date'].strftime('%Y-%m-%d')
          td item['chargeamount'] ? format_money(item['chargeamount']) : '-'
          td item['creditamount'] ? format_money(item['creditamount']) : '-'
          td item['description']
        end
      end
    end
  end

  def pay
    h3 "dues due:"
    if @dues[0] > 0
      div format_money(@dues[0]), :class => 'dues overdue'
      div "Overdue", :class => 'overdue'
    else
      div format_money(@dues[1]), :class => 'dues'
    end

    paymentform(@dues[0])
  end
  
  def userdashboard
    h3 "dues due:"
    if @dues[0] > 0
      div format_money(@dues[0]), :class => 'dues overdue'
      div "Overdue", :class => 'overdue'
    else
      div format_money(@dues[1]), :class => 'dues'
    end
    if @dues[0] > 0 or @dues[1] > 0
      a :href => R(Pay, @leagueid), :class => 'paylink' do
        span "Pay dues", :class => 'paybutton'
      end
    end
    paymenthistory
  end

  def paymentresult
    if @paystatus == :success
      div :class => 'successdiv' do
        amount = format_money(@details['amount'])
        "Thank you for paying! #{amount} has been credited to your account."
      end
      a 'Home', :href => R(User, @leagueid)
    else
      div :class => 'errordiv' do
        "Error #{@details}"
      end
    end
  end

  def crudfields(*fields)
    validfields = [:name, :value, :type]
    fields.each do |f|
      inputfields = f.select { |k,v| validfields.include? k }
      div do
        label do
          text f[:label]
          input inputfields
        end
      end
    end
  end

  def newuser
    h3 "Update profile"
    # TODO: statusdiv
    form :action => R(Newuser), :method => 'POST' do
      crudfields(
        # include old token so successful POST can destroy it
        {
          :type => 'hidden',
          :name => 'leagueid',
          :value => @leagueid,
        },
        { :label => "Password", :type => 'password', :name => 'password' },
        { :label => "Confirm password", :type => 'password',
          :name => 'password2'},
        {
          :label => "Legal name",
          :name => 'legalname',
          :value => @memberinfo['legalname']
        },
        {
          :label => "Derby name:",
          :name => 'derbyname',
          :value => @memberinfo['derbyname']
        })
      button "Save", :type => 'submit'
    end
  end
  def adduser
    if @addeduser
      div :class => 'successdiv' do
        text "Added user #{@addeduser[:name]} #{@addeduser[:email]}"
      end
    end
    h3 "Add user"
    form :action => R(LeagueNAdduser, @leagueid), :method => 'POST' do
      div do
        label do
          text "Name:"
          input :name => 'name'
        end
      end
      div do
        label do
          text "Email:"
          input :name => 'email'
        end
      end
      button "Add user", :type => 'submit'
    end
  end

  def layout
    html do
      head do
        title @title
        link :rel => 'stylesheet', :type => 'text/css', :href => '/style.css'
      end
      body do
        if @leagueid && !@nonavbar
          navbar
        end
        self << yield
      end
    end
  end
end
