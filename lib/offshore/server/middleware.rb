module Offshore
  class Middleware
    def initialize(app)
      @app = app
    end
    
    def init_requires
      return if @init_requires
      @init_requires = true
      
      # TODO: move this to a config block
      if defined?(Rails)
        begin
          require Rails.root.join("spec","spec_helper")
        rescue
          raise
        end
      end
    end

    def call(env)
      if (env["PATH_INFO"] =~ /^\/offshore_tests\/(.*)/) == 0
        status = 500     
        headers = {}
        hash = {"error" => "Unknown method: #{$1}"}
        
        begin
          case $1
          when "factory_create", "suite_start", "suite_stop", "test_start", "test_stop"
            status, hash = send($1, env)
          end
        rescue StandardError => e
          hash = {"error" => e.message}
          raise # for now
        end
        
        content = hash.to_json
        headers['Content-Type'] = "application/json"
        headers['Content-Length'] = content.length.to_s
        [status, headers, [content]]
      else
        @app.call(env)
      end
    end
  
    def factory_girl
      if defined? FactoryGirl
        return FactoryGirl
      elsif defined? Factory
        return Factory
      end
      return nil
    end
  
    def factory_create(env)
      hash = Rack::Request.new(env).params
      name = hash["name"]
      attributes = hash["attributes"] || {}
      
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
    
    def suite_start(env)
      init_requires  # set it up in memory
      [200, {"todo" => "log that the suite is running"}]
    end
    
    def suite_stop(env)
      [200, {"truth" => "nothing to see here."}]
    end
    
    def test_start(env)
      [200, {"todo" => "implement reset / lock"}]
    end
    
    def test_stop(env)
      [200, {"todo" => "implement unlock"}]
    end
    
  end
end