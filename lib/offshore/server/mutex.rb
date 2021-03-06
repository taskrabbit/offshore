# Adapted from... 
# https://github.com/kenn/redis-mutex/blob/master/lib/redis/mutex.rb
# https://github.com/kenn/redis-classy/blob/master/lib/redis/classy.rb

module Offshore
  #
  # Options
  #
  # :block  => Specify in seconds how long you want to wait for the lock to be released. Speficy 0
  #            if you need non-blocking sematics and return false immediately. (default: 1)
  # :sleep  => Specify in seconds how long the polling interval should be when :block is given.
  #            It is recommended that you do NOT go below 0.01. (default: 0.1)
  # :expire => Specify in seconds when the lock should forcibly be removed when something went wrong
  #            with the one who held the lock. (default: 10)
  #
  class Mutex
    
    DEFAULT_EXPIRE = 10*60*1000  # 10 minutes (I think)
    LockError = Class.new(StandardError)
    UnlockError = Class.new(StandardError)
    AssertionError = Class.new(StandardError)
    
    attr_reader :key
    def initialize(object, options={})
      @key = (object.is_a?(String) || object.is_a?(Symbol) ? object.to_s : "#{object.class.name}:#{object.id}")
      @block = options[:block] || 0   # defaults to not blocking (returns false)
      @sleep = options[:sleep] || 0.1
      @expire = options[:expire] || DEFAULT_EXPIRE
    end
    
    # get, del, etc
    def method_missing(command, *args, &block)
      self.class.send(command, @key, *args, &block)
    end

    def lock
      self.class.raise_assertion_error if block_given?
      @locking = false

      if @block > 0
        # Blocking mode
        start_at = Time.now
        while Time.now - start_at < @block
          @locking = true and break if try_lock
          sleep @sleep
        end
      else
        # Non-blocking mode
        @locking = try_lock
      end
      @locking
    end

    def try_lock
      now = Time.now.to_f
      @expires_at = now + @expire                       # Extend in each blocking loop
      return true   if setnx(@expires_at)               # Success, the lock has been acquired
      return false  if get.to_f > now                   # Check if the lock is still effective

      # The lock has expired but wasn't released... BAD!
      return true   if getset(@expires_at).to_f <= now   # Success, we acquired the previously expired lock
      return false  # Dammit, it seems that someone else was even faster than us to remove the expired lock!
    end

    def unlock(force = false)
      # Since it's possible that the operations in the critical section took a long time,
      # we can't just simply release the lock. The unlock method checks if expires_at
      # is the one we though, and do not release when the lock timestamp was overwritten.

      # FIXME TODO: bug here if this wasn't the one to lock it, but I don't have @expires_at in different threads, etc
      force = true
      if force
        # Redis#del with a single key returns '1' or nil
        !!del
      else
        false
      end
    end

    def with_lock
      if lock!
        begin
          @result = yield
        ensure
          unlock
        end
      end
      @result
    end

    def lock!
      lock or raise LockError, "failed to acquire lock #{key.inspect}"
    end

    def unlock!(force = false)
      unlock(force) or raise UnlockError, "failed to release lock #{key.inspect}"
    end

    class << self
      def db
        Offshore.redis
      end
      
      def method_missing(command, *args, &block)
        db.send(command, *args, &block)
      end
            
      def sweep
        return 0 if (all_keys = keys).empty?

        now = Time.now.to_f
        values = mget(*all_keys)

        expired_keys = all_keys.zip(values).select do |key, time|
          time && time.to_f <= now
        end

        expired_keys.each do |key, _|
          # Make extra sure that anyone haven't extended the lock
          del(key) if getset(key, now + DEFAULT_EXPIRE).to_f <= now
        end

        expired_keys.size
      end

      def lock(object, options = {})
        raise_assertion_error if block_given?
        new(object, options).lock
      end
      
      def unlock(object, options = {})
        raise_assertion_error if block_given?
        new(object, options).unlock
      end

      def lock!(object, options = {})
        new(object, options).lock!
      end
      
      def unlock!(object, options = {})
        raise_assertion_error if block_given?
        new(object, options).unlock!
      end

      def with_lock(object, options = {}, &block)
        new(object, options).with_lock(&block)
      end

      def raise_assertion_error
        raise AssertionError, 'block syntax has been removed from #lock, use #with_lock instead'
      end
    end
  end
end