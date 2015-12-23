require 'camping'

Camping.goes :PayDerbyDues

require_relative 'pdd-data'
require_relative 'pdd-helpers'
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
      $pdd.update_member(@memberid, hashgrep(@input, 'legalname', 'derbyname'))
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

  class Feeschedules < R '/league/(\d+)/feeschedules'
    def get(leagueid)
      check_auth!(leagueid, true)
      @feeschedules = $pdd.get_feeschedules(@leagueid)
      render :feeschedules
    end
    def post(leagueid)
      check_auth!(leagueid, true)
      $pdd.create_feeschedule(leagueid, input)
      redirect R(Feeschedules, leagueid)
    end
  end

  class Feeschedule < R '/feeschedule/(\d+)'
    def post(feescheduleid)
      feeschedule = $pdd.get_feeschedule(feescheduleid)
      check_auth!(feeschedule['leagueid'], true)
      if input.operation == 'delete'
        $pdd.delete_feeschedule(feescheduleid)
      else
        @input['amount'] = parse_money(@input['amount'])
        updates = hashgrep(@input, 'name', 'amount', 'intervalid')
        $pdd.update_feeschedule(feescheduleid, updates)
      end
      redirect R(Feeschedules, @leagueid)
    end
    def get(feescheduleid)
      @feeschedule = $pdd.get_feeschedule(feescheduleid)
      check_auth!(@feeschedule['leagueid'], true)
      render :feeschedule
    end
  end
  class FeescheduleNew < R '/league/(\d+)/feeschedule/new'
    def get(leagueid)
      check_auth!(leagueid, true)
      render :feeschedule
    end
    def post(leagueid)
      check_auth!(leagueid, true)
      $pdd.add_feeschedule(@leagueid, input.name, input.intervalid,
                           parse_money(input.amount))
      @success = "Created feeschedule ... (...)"
      redirect R(Feeschedules, leagueid)
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

  # /newuser - endpoint for links in signup emails.
  class Newuser
    # this is where you get to from a link in the signup email.
    # Shows you a form to update your info which POSTS to the same URL.
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
    # Where the form above gets submitted to. Update user info
    # and set password.
    def post()
      check_auth!(@input['leagueid'])
      if @input['password'] and @input['password2']
        if @input['password'] == @input['password2']
          $pdd.update_password(@memberid, @input['password'])
        end
      end
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
  
STYLESHEET = File.read('style.css')

require 'stripe'
def PayDerbyDues.create
  $pdd = PayDerbyDues::Data.new()
  Stripe.api_key = 'sk_test_8O5Gp4CY3grgclUrID3PX3N1'
end
