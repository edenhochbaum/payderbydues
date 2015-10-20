Camping.goes :PayDerbyDues

require_relative 'paymentform'
require_relative 'pdd-data'
require_relative 'pdd-views'

module PayDerbyDues::Controllers
  class LeagueN
    def get(leagueid)
      check_auth!(true, leagueid)
      @leaguename = $pdd.get_leaguename(leagueid)
      @members = $pdd.members(leagueid)
      render :leaguedashboard
    end
    def post(leagueid)
      check_auth(true, leagueid)
      # update league data
    end
  end
  class LeagueNAdduser
    def post(leagueid)
      check_auth!(true, leagueid)
      # add user

      # redirect -> leagueN
    end
  end
  class User < R '/league/(\d+)/member'
    def get(leagueid)
      check_auth!(false, leagueid)
      @leaguename = $pdd.get_leaguename(leagueid)
      @dues = $pdd.dues_due(@memberinfo['id'])

      render :userdashboard
    end
    def post
      # update user info
    end
  end
  
  class Pay < R '/league/(\d+)/pay'
    def post
      @memberid = check_auth!(false, leagueid)
      @amount = parse_money(@input['amount']) # XXX: handle errors!!!
      begin
        charge = Stripe::Charge.create(
          :amount => parse_money(@input['amount']),
          :currency => 'USD',
          :source => @input['stripeToken']
          # TODO: :destination => @league['stripe_accountid']
          # :application_fee => ...
        )
        $pdd.pay(@memberid, @input['amount'])
        @status = :success
        @details = charge
        render :paymentresult
      rescue Stripe::StripeError => e
        @status = :stripe_error
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
      check_auth!(true, leagueid)
      @leaguename = $pdd.get_leaguename(leagueid)
      @title = "Create charge"
      render :usercharge
    end
    # XXX: parse money
    def post(leagueid, userid)
      check_auth!(true, leagueid)
      if @input['type'] == 'charge'
        $pdd.add_invoiceitem(@memberinfo['id'], @input['amount'],
                             @input['description'])
        @chargeamount = [invoice.amount]
      elsif @input['type'] == 'credit'
        $pdd.pay(@memberinfo['id'], @input['amount'],
                 @input['description'])
      else  
        raise Exception.new('Unknown charge/credit type')
      end
      redirect R(LeagueN, @leagueid)
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
end

module PayDerbyDues::Helpers
  def check_auth!(admin = false, league = nil)
    @memberid = $pdd.check_token(@cookies['token'])
    if !@memberid
      redirect PayDerbyDues::Controllers::Index
      throw :halt
    end
    @leagueid = league.to_i
    @memberinfo = $pdd.get_leaguemember(@leagueid, @memberid)
    # XXX: check that memberinfo is valid
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
  include PaymentForm
end
  
STYLESHEET = File.read('style.css')

require 'stripe'
def PayDerbyDues.create
  $pdd = PayDerbyDues::Data.new()
  Stripe.api_key = 'sk_test_8O5Gp4CY3grgclUrID3PX3N1'
end
