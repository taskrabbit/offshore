module Offshore
  class Suite
    def hosts
      @hosts ||= []
    end
    
    def default
      hosts.first
    end
    
    def all_hosts!(method, *args)
      hosts.each do |host|
        host.send(method, *args)
      end
    end
  
    def start(server_array_or_hash)
      server_array = server_array_or_hash.is_a?(Array) ? server_array_or_hash : [server_array_or_hash]
      raise "Need one server" if server_array.size != 1
      
      server_array.each do |hash|
        hosts << Host.new(hash)
      end
      
      all_hosts!(:suite_start)
    end
  
    def stop
      Offshore.test # if the last one failed this will stop it
      all_hosts!(:suite_stop)
    end
  end
end
