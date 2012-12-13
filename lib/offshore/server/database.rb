module Offshore
  module Database
    extend self
    
    GENERATE_KEY = "database:generate"
    LOCK_KEY = "database:lock"
    SHUTDOWN_KEY = "database:shutdown"
    
    def redis
      Offshore.redis
    end
    
    def lock
      raise Offshore::CheckBackLater.new("Database in use") unless Offshore::Mutex.lock(LOCK_KEY)
    end
    
    def unlock
      Offshore::Mutex.unlock!(LOCK_KEY)
    end
    
    def startup(background=true)
      redis.del(LOCK_KEY)
      redis.del(GENERATE_KEY)
      redis.del(SHUTDOWN_KEY)
      create_schema(background)
    end
    
    def shutdown
      redis.incr(SHUTDOWN_KEY, 1)
    end
    
    def init
      # TODO: how to let these finish and also stall startup.
      # should it be per test
      # what about db reconnections?
      raise "Database shutting down. No new connections, please." if redis.get(SHUTDOWN_KEY)
      create_schema(true)
    end
    
    def rollback
      # TODO: binlog
    end
    
    def start
      lock
      rollback
    end
    
    def stop
      unlock
    end
    
    private
    
    def create_schema(background)
      times = redis.incr(GENERATE_KEY) # get the incremented counter value      
      return unless times == 1
      
      if background
        build_in_fork
      else
        build_in_process
      end
    end
    
    def build_in_fork
      lock
      otherProcess = fork { `bundle exec rake offshore:seed_and_unlock --trace` }
      Process.detach(otherProcess)
    end
    
    def build_in_process
      lock
      #TODO: configurable, what rake job if not exist
      %x(bundle exec rake offshore:seed_and_unlock)
      unless $? == 0
        init
        raise "rake offshore:seed failed!"
      end
    end
  end
end