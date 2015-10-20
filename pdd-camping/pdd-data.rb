require 'bcrypt'
require 'date'
require 'dbi'

module PayDerbyDues
  class Data
    def initialize()
      @dbh = DBI.connect("DBI:Pg:payderbydues", ENV['DBUSERNAME'], ENV['DBPASSWORD'])
    end
    def getleaguename(leagueid)
      @dbh.select_one('select name from league where id = ?', leagueid)[0]
    end

    def members(leagueid)
      @dbh.select_all(%q{select leaguemember.id id, legalname, derbyname,
                                email, member.id memberid, feescheduleid
                         from leaguemember, member
                         where leaguemember.leagueid = ?
                           and leaguemember.memberid = member.id}, leagueid)
    end


    def get_leaguemember(leagueid, memberid)
      @dbh.select_one(%q{select leaguemember.id id, legalname, derbyname, email,
                                member.id memberid, feescheduleid
                         from leaguemember, member
                         where leaguemember.leagueid = ?
                           and leaguemember.memberid = ?}, leagueid, memberid)
    end

    def get_leaguename(leagueid)
      @dbh.select_one(%q{select name from league where id = ?}, leagueid)[0]
    end

    def dues_due(leaguememberid)
      past = @dbh.select_one(%q{select coalesce(sum(amount),0)
                                from invoiceitem
                                where leaguememberid = ?
                                  and duedate < now()}, leaguememberid)[0]
      future = @dbh.select_one(%q{select coalesce(sum(amount),0)
                                  from invoiceitem
                                  where leaguememberid = ?
                                    and duedate >= now()}, leaguememberid)[0]
      paid = @dbh.select_one(%q{select coalesce(sum(amount),0)
                                from payment
                                where leaguememberid = ?}, leaguememberid)[0]
      overdue = [past - paid, 0].max
      balance = past + future - paid
      return [overdue, balance]
    end
    def get_history(leaguememberid)
      historyquery = %q{
        select duedate date, amount chargeamount,
               null creditamount, description
        from invoiceitem where leaguememberid = ?
      union all
        select date, null chargeamount, amount creditamount, description
        from payment where leaguememberid = ?}
      @dbh.select_all("select date, chargeamount, creditamount, description from (#{historyquery}) hq order by date desc",
                      leaguememberid, leaguememberid)
    end

    def add_invoiceitem(leaguememberid, amount, description)
      @dbh.do(%q{insert into invoiceitem
              (amount, leaguememberid, description, duedate)
              values (?, ?, ?, now())},
              amount, leaguememberid, description)
    end

    def pay(leaguememberid, amount, description, stripe_chargeid = nil)
      @dbh.do(%q{insert into payment
                (leaguememberid, amount, description, date, stripe_chargeid)
                 values (?, ?, ?, now(), ?)},
              leaguememberid, amount, description, stripe_chargeid)
    end
    
    def check_token(token)
      @dbh.select_one(%q{select memberid from token
                         where value = ? and expires >= now()}, token)[0] rescue nil
    end

    def _gen_token()
      open('/dev/urandom') do |r|
        return r.read(16).unpack('H*')[0]
      end
    end

    def check_league_admin(memberid, leagueid)
      roleid = @dbh.select_one(%q{
        select roleid from leaguememberrole, leaguemember
         where leaguemember.memberid = ? and leaguemember.leagueid = ?
           and leaguememberrole.leaguememberid = leaguemember.id},
                              memberid, leagueid)
      return (roleid['roleid'] == 0)
    end

    def leaguememberships(email)
      @dbh.select_all(%q{select leaguemember.leagueid
                         from leaguemember, member
                         where member.email = ?
                           and leaguemember.memberid = member.id},
                      email)
    end
    
    def login(username, password)
      (memberid, hash) = @dbh.select_one(%q{select id, password from member
                                       where email = ?}, username)
      return nil unless memberid
      pw = BCrypt::Password.new(hash)
      if pw == password
        token = _gen_token()
        @dbh.do('insert into token (memberid, value, expires)
                 values (?, ?, now() + ?)',
               memberid, token, '1 day')
        return token
      end
      return nil
    end
  end
end
