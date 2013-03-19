module Offshore
  module Database
    extend self
    
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
      redis.del(SHUTDOWN_KEY)
      redis.del(SUITES_LIST_KEY)
    end
    
    def startup
      Logger.info(" Database.startup")
      reset
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
      
      Offshore::Database.unlock unless ENV['MULTI_OFFSHORE']  # no reason to keep everyone waiting if I'm the only one
      
      if redis.get(SHUTDOWN_KEY)
        Logger.info("   .... database shutting down. Exiting.")
        raise "Database shutting down. No new connections, please."
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
    
    def snapshot
      Offshore::Snapshot::Template
    end
  end
end