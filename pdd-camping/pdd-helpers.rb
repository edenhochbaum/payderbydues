require_relative 'paymentform'

module PayDerbyDues::Helpers
  def check_auth!(league, admin = false)
    @memberid = $pdd.check_token(@cookies['token'])
    if !@memberid
      redirect PayDerbyDues::Controllers::Index
      throw :halt
    end
    @leagueid = league.to_i
    @memberinfo = $pdd.get_leaguemember(@leagueid, @memberid)
    if !(@memberinfo[0] rescue nil)
      r(403, "You are not a member of this league!")
      throw :halt
    end
    @leaguename = $pdd.get_leaguename(@leagueid)
    if admin and not $pdd.check_league_admin(@memberid, league)
      r(403, "You are not an admin!")
      throw :halt
    end
  end
  def format_money(amount)
    sprintf "$%d.%02d", amount / 100, amount % 100
  end

  INTERVALS = ["One-time", "Annually", "Monthly", "Weekly", "Daily"]
  def format_interval(interval)
    return INTERVALS[interval]
  end

  def interval_options(name, current)
    select :name => name do
      INTERVALS.each_index do |i|
        if current == i
          option INTERVALS[i], :value => i.to_s, :selected => 1
        else
          option INTERVALS[i], :value => i.to_s
        end
      end
    end
  end
  def parse_money(amount)
    amount =~ /^\s*\$?\s*(\d+)(?:\.(\d{2}))?\s*/ or raise Exception.new("Couldn't parse money")
    return $1.to_i * 100 + $2.to_i
  end
  def send_email(email, name, token)
    url = URL(Newuser, { :token => token })
    status = system('welcome_email.pl',
                    '--email', email,
                    '--name', name,
                    '--link', url.to_s,
                    '--league', @leaguename,
                   '--invitedby', @memberinfo['legalname'])
    if !status
      raise Exception.new("Couldn't send email #{$?}")
    end
  end

  def hashgrep(hash, *keys)
    hash.select { |k, v| keys.include? k }
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

  include PaymentForm
end
