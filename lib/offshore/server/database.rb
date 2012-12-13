module Offshore
  module Database
    extend self
    
    GENERATE_KEY = "database:generate"
    LOCK_KEY = "database:lock"
    SHUTDOWN_KEY = "database:shutdown"
    SUITES_LIST_KEY = "suites:list"
    
    def redis
      Offshore.redis
    end
    
    def lock
      Logger.info(" Database.lock")
      if Offshore::Mutex.lock(LOCK_KEY)
        Logger.info("    .... lock acquired")
      else
        Logger.info("    .... locked")
        raise Offshore::CheckBackLater.new("Database in use")
      end
    end
    
    def unlock
      Logger.info(" Database.unlock")
      Offshore::Mutex.unlock!(LOCK_KEY)
    end
    
    def reset
      Logger.info(" Database.reset")
      redis.del(LOCK_KEY)
      redis.del(GENERATE_KEY)
      redis.del(SHUTDOWN_KEY)
      redis.del(SUITES_LIST_KEY)
    end
    
    def startup(background=true)
      Logger.info(" Database.startup")
      reset
      create_schema(background)
    end
    
    def shutdown
      Logger.info(" Database.shutdown")
      redis.incr(SHUTDOWN_KEY, 1)
    end
    
    def init
      # TODO: how to let these finish and also stall startup.
      # should it be per test
      # what about db reconnections?
      Logger.info(" Database.init")
      if redis.get(SHUTDOWN_KEY)
        Logger.info("   .... databse shutting down. Exiting.")
        raise "Database shutting down. No new connections, please."
      else
        create_schema(true)
      end
    end
    
    def schema_snapshot
      Logger.info(" Database.schema_snapshot")
      snapshot.create
    end
    
    def rollback
      Logger.info(" Database.rollback")
      snapshot.rollback
    end
        
    private
    
    def create_schema(background)
      times = redis.incr(GENERATE_KEY) # get the incremented counter value      
      unless times == 1
        Logger.info("   Database.create_schema: already created")
        return
      end
      
      Logger.info("   Database.create_schema: creating....")
      lock
      if background
        build_in_fork
      else
        build_in_process
      end
    end
    
    
    def build_in_fork
      Logger.info("    ..... building in fork")
      otherProcess = fork { `bundle exec rake offshore:seed_schema --trace`; `bundle exec rake offshore:unlock --trace`; }
      Process.detach(otherProcess)
    end
    
    def build_in_process
      Logger.info("    ..... building in process")
      #TODO: configurable, what rake job if not exist
      %x(bundle exec rake offshore:seed_schema --trace)
      unless $? == 0
        reset
        raise "rake offshore:seed_schema failed!"
      end
      unlock
    end
    
    def snapshot
      Offshore::Snapshot::Template
    end
  end
end