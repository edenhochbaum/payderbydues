
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
    h2 "Add member:"
    form :method => 'POST', :action => R(LeagueNAdduser, @leagueid) do
      label do
        span 'Email address:'
        input :name => 'email'
      end
      # TODO: pending email invitations
      button "Invite user", :type => 'submit'
    end
    h2 "League account information"
    form :method => 'POST', :action => R(LeagueN, @leagueid) do
      # TODO: we want some javascript to only post stuff that was touched
      # stripe account id
      # stripe private key
      # stripe public key
      # league name
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
      # span :class => 'navitem' { a "Switch League", :href => R(Leagues, @leagueid) }
      if @admin
        span :class => 'navitem' do
          a "League Admin", :href => R(LeagueAdmin, @leagueid)
        end
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
        select :name => 'type' do # XXX: radio button
          option "Charge", :value => 'charge'
          option "Credit", :value => 'credit'
        end
      end
      button "Create Charge", :type => 'submit'
    end
    paymenthistory
  end

  def paymenthistory
    table do
      thead do
        th "Date"
        th "Charge amount"
        th "Credit amount"
        th "Description"
      end
      @historyitems.each do |item|
        tr do
          td item['date'].strftime('%Y-%m-%d')
          td item['chargeamount'] ? format_money(item['chargeamount']) : '-'
          td item['creditamount'] ? format_money(item['creditamount']) : '-'
          td item['description']
        end
      end
    end
  end
  
  def userdashboard
    h3 "dues due:"
    if @dues[0] > 0
      div format_money(@dues[0]), :class => 'dues overdue'
      div "Overdue", :class => 'overdue'
    else
      div format_money(@dues[1]), :class => 'dues'
    end
    paymentform
    paymenthistory
  end

  def paymentresult
    # username
    # payment
    if @status == :error
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

  def layout
    html do
      head do
        title @title
        link :rel => 'stylesheet', :type => 'text/css', :href => '/style.css'
        # TODO: scripts
      end
      body do
        if @leagueid
          navbar
        end
        self << yield
      end
    end
  end
end
