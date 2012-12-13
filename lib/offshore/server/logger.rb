module Offshore
  module Logger
    extend self
    
    def say(type, message)
      message = "[Offshore][#{type}][#{Time.now.to_i}][#{Time.now}] #{message}"
      if defined?(Rails)
        Rails.logger.send(type, message)
      else
        puts message
      end
    end
    
    def info(message)
      say(:info, message)
    end
    
    def error(message)
      say(:error, message)
    end
  end
end