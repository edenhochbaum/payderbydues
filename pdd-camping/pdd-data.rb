# pdd-data - a simplistic "data layer" for PayDerbyDues
# Naming conventions:
#  get_foo: gets a row from the foo table
#  add_foo: adds a row to the foo table
#  update_foo: updates a row in the foo table. Takes an id and a hash
#    of updates to apply.
# Also includes functions to deal with auth tokens, since those live
# in the database.
require 'bcrypt'
require 'date'
require 'dbi'

module PayDerbyDues
  class Data
    def initialize()
      hostpart = ":#{ENV['DBHOST']}" if ENV['DBHOST']
      @dbh = DBI.connect("DBI:Pg:payderbydues#{hostpart}",
                         ENV['DBUSERNAME'], ENV['DBPASSWORD'])
    end

    def members(leagueid)
      @dbh.select_all(%q{select leaguemember.id id, legalname, derbyname,
                                email, member.id memberid,
                                feeschedule.name feeschedulename
                         from leaguemember, member, feeschedule
                         where leaguemember.leagueid = ?
                           and leaguemember.memberid = member.id
                           and leaguemember.feescheduleid = feeschedule.id},
                      leagueid)
    end

    def get_leaguemember(leagueid, memberid)
      @dbh.select_one(%q{select leaguemember.id id, legalname, derbyname, email,
                                member.id memberid, feescheduleid
                         from leaguemember, member
                         where leaguemember.memberid = member.id
                           and leaguemember.leagueid = ?
                           and leaguemember.memberid = ?}, leagueid, memberid)
    end
    def _insert_with_id(sql, *binds)
      stmt = @dbh.prepare(sql)
      stmt.execute(*binds)
      return stmt.fetch()[0]
    end
    def add_member(email, name)
      _insert_with_id(%q{insert into member (email, legalname)
                         values (?, ?) returning id}, email, name)
    end
    def add_leaguemember(leagueid, memberid)
      _insert_with_id(%q{insert into leaguemember
                        (leagueid, memberid, feescheduleid)
                         values (?, ?, 1) returning id}, leagueid, memberid)
    end

    def get_leaguename(leagueid)
      @dbh.select_one(%q{select name from league where id = ?}, leagueid)[0]
    end

    def get_feeschedules(leagueid)
      @dbh.select_all(%{select * from feeschedule where leagueid = ?},
                      leagueid)
    end

    def get_feeschedule(feescheduleid)
      @dbh.select_one(%q{select * from feeschedule where id = ?}, feescheduleid)
    end

    def add_feeschedule(leagueid, name, interval, amount)
      _insert_with_id(%q{insert into feeschedule (leagueid, name,
                                              intervalid, amount)
                         values (?, ?, ?, ?) returning id},
                      leagueid, name, interval, amount)
    end

    def delete_feeschedule(feescheduleid)
      @dbh.do(%{delete from feeschedule where id = ?}, feescheduleid)
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

    def update_password(memberid, password)
      crypted = BCrypt::Password.create(password, :cost => 12).to_s
      @dbh.do(%q{update member set password = ? where id = ?},
              crypted, memberid)
    end
    def crud_update(table, id, updates)
      sets = updates.keys.map { |k| k.to_s + " = ?" }.join(',')
      @dbh.do(%Q{update #{table} set #{sets} where id = #{id}},
              *updates.values)
    end
    # TODO: meta-magicalize this
    def update_memberinfo(memberid, updates)
      crud_update('member', memberid, updates)
    end

    def update_feeschedule(id, updates)
      crud_update('feeschedule', id, updates)
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

    def leaguememberships_memberid(email)
      @dbh.select_all(%q{select leaguemember.leagueid
                         from leaguemember
                         where leaguemember.memberid = ?},
                      email)
    end

    def add_token(memberid, validity = '1 day')
      token = _gen_token()
      @dbh.do('insert into token (memberid, value, expires)
               values (?, ?, now() + ?)',
               memberid, token, validity)
      return token
    end

    def destroy_token(token)
      @dbh.do('delete from token where value = ?', token)
    end

    def login(username, password)
      row = @dbh.select_one(%q{select id, password from member
                                       where email = ?}, username)
      return nil unless row
      (memberid, hash) = [row[0], row[1]]
      pw = BCrypt::Password.new(hash)
      if memberid and pw == password
        return add_token(memberid)
      else
        return nil
      end
    end
  end
end
