require 'erb'
require 'digest/md5'
require 'mysql2'

module Offshore
  module Snapshot
    extend self
    
    def config
      return @config if @config
      
      raise "Only supported in Rails for now" unless defined?(Rails)
      
      yml = Rails.root.join("config", "database.yml")
      hash = YAML.load(ERB.new(File.read(yml)).result)['test']

      @config = {}
      ['username', 'password', 'host', 'port', 'database', 'collation', 'charset'].each do |key|
        if hash['master'] && hash['master'].has_key?(key)
          @config[key] = hash['master'][key]
        else
          @config[key] = hash[key]
        end
      end
      
      @config
    end
  end
end

module Offshore
  module Snapshot
    module Template
      extend self
      
      SNAPSHOT_KEY = "snapshot:checksum"
      
      def create
        use_db(test_db)
        use_db(template_db)
        clone(test_db, template_db)
        record_checksum(test_db)
      end
      
      def rollback
        use_db(test_db)
        stored = Offshore.redis.get(SNAPSHOT_KEY)
        sum = db_checksum(test_db)
        
        if stored == sum
          Logger.info("   Snapshot checksum equal - not cloning")
        else
          Logger.info("   Snapshot checksum not equal - cloning")
          use_db(template_db)
          clone(template_db, test_db)
          record_checksum(test_db) unless stored
        end
      end
      
      
      def rollback2
        use_db(test_db)
        use_db(template_db)
        if equal_checksum?(template_db, test_db)
          Logger.info("   Snapshot checksum equal - not cloning")
        else
          Logger.info("   Snapshot checksum not equal - cloning")
          clone(template_db, test_db)
        end
      end
      
      private
      
      def record_checksum(db)
        sum = db_checksum(db)
        Logger.info("    Snapshot checksum: #{sum}")
        Offshore.redis.set(SNAPSHOT_KEY, sum)
      end
      
      def equal_checksum?(from, to)
        tem = db_checksum(from)
        sum = db_checksum(to)
        Logger.info("    Snapshot checksum (calculated) compare: #{sum}  ==  #{tem}")
        tem == sum
      end
      
      def test_db
        @test_db ||= make_conn
      end

      def template_db
        @template_db ||= make_conn("_offshore_template")
      end

      def clone(from, to)
        empty_tables(to)
        copy_tables(from, to)
        copy_data(from, to)
      end
      
      def db_checksum(db)
        string = ""
        name = current_db(db)
        get_tables(db).each do |table|
          row = db.query("CHECKSUM TABLE `#{name}`.`#{table}`")
          string << ":"
          string << row.first["Checksum"].to_s
        end

        Digest::MD5.hexdigest(string)
      end
      
      def make_conn(append="")
        ar = Offshore::Snapshot.config
        config = {}
        config['reconnect'] = true
        config['flags'] = Mysql2::Client::MULTI_STATEMENTS
        
        ['username', 'password', 'host', 'port'].each do |key|
          config[key.to_sym] = ar[key]
        end
        
        client = Mysql2::Client.new(config)
        client.instance_variable_set("@offshore_db_name", "#{ar['database']}#{append}")
        client
      end

      def use_db(db)
        original_db = current_db(db)
        begin
          db.query("create database `#{original_db}` DEFAULT CHARACTER SET `utf8`") # TODO forcing UTF8
        rescue
        end
        db.query("use `#{original_db}`")
      end

      def empty_tables(db)
        name = current_db(db)
        get_tables(db).each do |table|
          db.query("drop table if exists `#{name}`.`#{table}`")
        end
      end
      
      def copy_tables(from, to)
        from_db = current_db(from)
        to_db = current_db(to)
        get_tables(from).each do |table|
          to.query("create table `#{to_db}`.`#{table}` like `#{from_db}`.`#{table}`")
        end
      end

      def copy_data(from, to)
        from_db = current_db(from)
        to_db = current_db(to)
        get_tables(from).each do |table|
          to.query("insert into `#{to_db}`.`#{table}` select * from `#{from_db}`.`#{table}`")
        end
      end

      def current_db(db)
        db.instance_variable_get("@offshore_db_name")
        # db.query("select database()").first.values[0]
      end

      def get_tables(db)
        table_array = []
        db.query("show tables").each do |row|
          table_array << row.values[0]
        end
        table_array
      end
      
    end
  end
end