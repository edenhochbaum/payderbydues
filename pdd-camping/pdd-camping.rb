Camping.goes :PayDerbyDues

require_relative 'paymentform'
require_relative 'pdd-data'
require_relative 'pdd-views'

module PayDerbyDues::Controllers
  class LeagueN
    def get(leagueid)
      check_auth!(leagueid, true)
      @members = $pdd.members(leagueid)
      render :leaguedashboard
    end
    def post(leagueid)
      check_auth!(leagueid, true)
      # TODO: update league data
    end
  end
  class LeagueNAdduser
    def get(leagueid)
      check_auth!(leagueid, true)
      render :adduser
    end
    def post(leagueid)
      check_auth!(leagueid, true)
      begin
        memberid = $pdd.add_member(@input['email'], @input['name'])
        leaguememberid = $pdd.add_leaguemember(@leagueid, memberid)
        token = $pdd.add_token(memberid, '1 week')

        send_email(@input['email'], @input['name'], token)
        @addeduser = { :email => @input['email'], :name => @input['name'] }
      rescue => e
        @error = e
        # TODO: actually handle errors (duplicate emails etc.)
        raise e
      end
      render :adduser
    end
  end
  class User < R '/league/(\d+)/member'
    def get(leagueid)
      check_auth!(leagueid)
      @dues = $pdd.dues_due(@memberinfo['id'])
      @historyitems = $pdd.get_history(@memberinfo['id'])
      render :userdashboard
    end
    def post
      check_auth!(leagueid)
      if @input['password'] and @input['password2']
        # TODO: check errors, also case where password is not being set.
        if @input['password'] == @input['password2']
          $pdd.update_password(@memberid, @input['password'])
        end
      end
      $pdd.update_member(@memberid, hashgrep(@input, 'legalname', 'derbyname'))
      # update user info
    end
  end
  
  class Pay < R '/league/(\d+)/pay'
    def get(leagueid)
      check_auth!(leagueid)
      @dues = $pdd.dues_due(@memberinfo['id'])
      render :pay
    end

    def post(leagueid)
      check_auth!(leagueid)
      begin
        @amount = parse_money(@input['amount']) # XXX: handle errors!!!
      rescue => e
        @paystatus = :user_error
        @details = e
        render :paymentresult
      end
      begin
        charge = Stripe::Charge.create(
          :amount => @input['amount'], #parse_money(@input['amount']),
          :currency => 'USD',
          :source => @input['stripeToken']
          # TODO: :destination => @league['stripe_accountid']
          # :application_fee => ...
        )
        $pdd.pay(@memberinfo['id'], charge.amount, 'Paid dues', charge.id)
        @paystatus = :success
        @details = charge
        render :paymentresult
      rescue Stripe::StripeError => e
        @paystatus = :stripe_error
        @details = e
        render :paymentresult
      end
    end
  end

  class Style < R '/style.css'
    def get
      @headers['Content-Type'] = 'text/css; charset=utf-8'
      STYLESHEET
    end
  end
  
  class UserCharge < R '/league/(\d+)/user/(\d+)/charge'
    def get(leagueid, userid)
      check_auth!(leagueid, true)
      @title = "Create charge"
      @historyitems = $pdd.get_history(@memberinfo['id'])

      render :usercharge
    end

    def post(leagueid, userid)
      check_auth!(leagueid, true)
      if @input['type'] == 'charge'
        $pdd.add_invoiceitem(@memberinfo['id'], parse_money(@input['amount']),
                             @input['description'])
      elsif @input['type'] == 'credit'
        $pdd.pay(@memberinfo['id'], parse_money(@input['amount']),
                 @input['description'])
      else  
        raise Exception.new('Unknown charge/credit type')
      end

      redirect R(UserCharge, leagueid, userid)
    end
  end
  
  class Index
    def get
      render :loginform
    end
  end
  class Webhook
    def post
      JSON.parse(@request.body)
      # TODO: do something
      r(200, "Success")
    end
  end
  class Newuser
    def get()
      memberid = $pdd.check_token(@input['token'])
      if !memberid
        r(403, "Your signup link has expired. Please contact your league admin for a new one")
        throw :halt
      end
      @cookies['token'] = $pdd.add_token(memberid)
      leaguememberships = $pdd.leaguememberships_memberid(memberid)
      if leaguememberships.length != 1
        r(500, "TODO: multiple league membership")
        throw :halt
      end
      @leagueid = leaguememberships[0][0].to_i
      @memberinfo = $pdd.get_leaguemember(@leagueid, memberid)
      @nonavbar = true
      render :newuser
    end
    def post()
      check_auth!(@input['leagueid'])
      $pdd.update_memberinfo(@memberid, @input.select {|k,v| ['legalname', 'derbyname'].include? k })
      redirect R(User, @leagueid)
    end
  end

  class Login
    def post
      token = $pdd.login(input.username, input.password)
      if !token
        @info = "Bad username or password"
        render :loginform
      else
        @cookies['token'] = token
        leaguememberships = $pdd.leaguememberships(input.username)
        if leaguememberships.length == 1
          if leaguememberships[0]['roleid'] == 0
            redirect R(LeagueN, leaguememberships[0]['leagueid'])
          else
            redirect R(User, leaguememberships[0]['leagueid'])
          end
        else
          r(500, "TODO: membership in multiple leagues")
          # TODO: R(Leagues) lets you pick leagues by user
        end
      end
    end
  end

  class Logout
    def get
      $pdd.destroy_token(@cookies['token'])
      @cookies.delete('token')
      redirect R(Index)
    end
  end
end

module PayDerbyDues::Helpers
  def check_auth!(league, admin = false)
    @memberid = $pdd.check_token(@cookies['token'])
    if !@memberid
      redirect PayDerbyDues::Controllers::Index
      throw :halt
    end
    @leagueid = league.to_i
    @memberinfo = $pdd.get_leaguemember(@leagueid, @memberid)
    if !@memberinfo
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
  def parse_money(amount)
    amount =~ /^\s*(\d+)(?:\.(\d{2}))?\s*/ or raise Exception.new("Couldn't parse money")
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
  include PaymentForm
end
  
STYLESHEET = File.read('style.css')

require 'stripe'
def PayDerbyDues.create
  $pdd = PayDerbyDues::Data.new()
  Stripe.api_key = 'sk_test_8O5Gp4CY3grgclUrID3PX3N1'
end
