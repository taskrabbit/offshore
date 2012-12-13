require "faraday"

module Offshore
  class Host
#    def client
#      return @http if @http
#      @http = Net::HTTP.new(host, port)
#      # @http.use_ssl = true
#      # @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
#      @http
#    end
#    
#    def post(append_path, attributes)
#      request = Net::HTTP::Post.new()
#      request.set_form_data(attributes)
#      response = client.request(request)
#      response.value
#      JSON.parse(response.body)
#    end

    def base_uri
      with_http = host
      with_http = "http://#{host}" unless (host =~ /^https?:/) == 0
      need_port = port || 80
      "#{with_http}:#{need_port}"
    end
  
    def connection
      return @connection if @connection
      connection_class = Faraday.respond_to?(:new) ? ::Faraday : ::Faraday::Connection

      timeout_seconds = 5*60 # 5 minutes
      @connection = connection_class.new(base_uri, :timeout => timeout_seconds) do |builder|
        builder.use Faraday::Request::UrlEncoded  if defined?(Faraday::Request::UrlEncoded)
        builder.adapter Faraday.default_adapter
      end
      @connection
    end
    
    def post(append_path, attributes={})
      attributes[:hostname] = `hostname`  # always send hostname
      
      while true do
        http_response = connection.post("#{self.path}/#{append_path}", attributes)
        if http_response.success?
          return MultiJson.decode(http_response.body)
        elsif http_response.status.to_s == Offshore::WAIT_CODE.to_s
          sleep 2 # two seconds and try again
        else
          begin
            hash = MultiJson.decode(http_response.body)
            message = "Error in offshore connection (#{append_path}): #{hash}"
          rescue
            message = "Error in offshore connection (#{append_path}): #{http_response.status}"
          end
          raise message
        end
      end
    end
    
    attr_reader :host, :port
    def initialize(options)
      @host = options[:host]
      @port = options[:port]
      @path = options[:path]
      @snapshot = options[:snapshot]
    end
    
    def snapshot_name
      return nil if @snapshot == true
      return "none" if @snapshot == false
      @snapshot
    end
    
    def path
      @path ||= "/offshore_tests"
    end
    
    def suite_start
      attributes = {}
      attributes[:snapshot] = snapshot_name
      hash = post(:suite_start, attributes)
    end
    
    def suite_stop
      hash = post(:suite_stop)
    end
    
    def test_start(name)
      hash = post(:test_start, { :name => name })
    end
    
    def test_stop(name)
      hash = post(:test_stop, { :name => name })
    end
    
    def factory_create(name, attributes={})
      data = { :name => name }
      data[:attributes] = attributes
      hash = post(:factory_create, data)
      factory_object(hash)
    end
    
    # TODO: move this to a config block
    def factory_object(hash)
      hash["class_name"].constantize.find(hash["id"])
    end
    
  end
end