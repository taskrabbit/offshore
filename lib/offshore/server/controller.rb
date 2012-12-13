module Offshore
  class Controller
    attr_reader :params
    def initialize(hash)
      @params = hash
    end
    
    def suite_start
      suite_key_set(params)
      [200, {"todo" => "log that the suite is running"}]
    end
    
    def suite_stop
      suite_key_clear
      [200, {"action" => "cleared"}]
    end
    
    def test_start
      Logger.info("  Start: #{params["name"]}")
      Offshore::Database.lock
      Offshore::Database.rollback if suite_key_options["snapshot"] != "none"
      [200, {"action" => "reset / lock"}]
    end
    
    def test_stop
      Logger.info("   Stop: #{params["name"]}")
      Offshore::Database.unlock
      [200, {"action" => "unlocked"}]
    end
    
    def factory_create      
      name = params["name"]
      raise "Need a factory name" unless name
      attributes = params["attributes"] || {}
      
      clazz = factory_girl
      require "factory_girl" unless clazz
      clazz = factory_girl
      
      begin
        val = clazz.create(name, attributes)
        out = {:class_name => val.class.name, :id => val.id, :attributes => val.attributes}
        status = 200
      rescue ActiveRecord::RecordInvalid => invalid
        out = {:error => invalid.record.errors.full_messages.join(",") }
        status = 422
      end
      [status, out]
    end
    
    private
    
    def factory_girl
      if defined? FactoryGirl
        return FactoryGirl
      elsif defined? Factory
        return Factory
      end
      return nil
    end
    
    def suite_key_set(val)
      Offshore.redis.set(suite_key, MultiJson.encode(val))
      @suite_key_options = nil
    end
    
    def suite_key_clear
      Offshore.redis.del(suite_key)
    end
    
    def suite_key_options
      @suite_key_options ||= MultiJson.decode(Offshore.redis.get(suite_key) || "{}")
    end
    
    def suite_key
      raise "need a hostname" unless params["hostname"]
      "suite:#{params["hostname"]}:options"
    end

  end
end