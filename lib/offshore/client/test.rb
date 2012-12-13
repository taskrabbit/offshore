module Offshore
  class Test
    def uuid
      @uid ||= rand(99999999).to_s
    end
    
    def get_name(example)
      name = nil
      name = example.full_description if example.respond_to?(:full_description)
      name ||= "unknown"
      "#{uuid} #{name}"
    end
    
    def run!(example)
      raise "already run test: #{get_name(@run_example)}" if @run_example
      @run_example = example
    end
    
    def run?
      !!@run_example
    end

    def start(example=nil)
      run!(example)
      Offshore.suite.all_hosts!(:test_start, get_name(example))
    end
  
    def stop(example=nil)
      Offshore.suite.all_hosts!(:test_stop, get_name(example))
      Offshore.send(:internal_test_ended)
    end
    
    def failed
      raise "have not run!" unless @run_example
      stop(@run_example)
    end
  
  end
end
