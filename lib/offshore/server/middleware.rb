module Offshore
  class Middleware
    def initialize(app)
      @app = app
    end
    
    def init_server
      Offshore::Database.init # has its own singleton code
    end
    
    def init
      init_server
    end

    def call(env)
      if offshore_request?(env)
        offshore_call(env)
      else
        @app.call(env)
      end
    end

    def offshore_request?(env)
      return false unless Offshore.enabled?
      !!offshore_method(env)
    end

    def offshore_method(env)
      env["PATH_INFO"] =~ /^\/offshore_tests\/(.*)/
      $1
    end
  
    def offshore_call(env)
      status = 500     
      headers = {}
      method = offshore_method(env)
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