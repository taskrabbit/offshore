module Offshore
  class Middleware
    def initialize(app)
      @app = app
    end
    
    def init_server
      Offshore::Database.init # has it's own singleton code
    end
    
    def init_thread
      return if @init_thread
      @init_thread = true
      
      # TODO: move this to a config block
      if defined?(Rails)
        begin
          require Rails.root.join("spec","spec_helper")
        rescue
          raise
        end
      end
    end
    
    def init
      init_thread
      init_server
    end


    def call(env)
      if offshore_request?
        offshore_call($1, env)
      else
        @app.call(env)
      end
    end

    def offshore_request?
      return false unless ENV['OFFSHORE'].to_s == 'true'
      (env["PATH_INFO"] =~ /^\/offshore_tests\/(.*)/) == 0
    end
  
    def offshore_call(method, env)
      status = 500     
      headers = {}
      hash = {"error" => "Unknown method: #{method}"}
      
      Logger.info("Offshore Tests Action: #{method}")
      
      begin
        case method
        when "factory_create", "suite_start", "suite_stop", "test_start", "test_stop"
          init if method == "suite_start"
          controller = Controller.new(Rack::Request.new(env).params)
          status, hash = controller.send(method)
        end
      rescue CheckBackLater => e
        hash = {"error" => e.message}
        status = Offshore::WAIT_CODE
      rescue StandardError => e
        hash = {"error" => e.message}
        status = 500
        raise # for now
      end
      
      content = hash.to_json
      headers['Content-Type'] = "application/json"
      headers['Content-Length'] = content.length.to_s
      out = [status, headers, [content]]
      Logger.info("Offshore Tests #{method}... returns: #{out.to_s}")
      out
    end
  end
end