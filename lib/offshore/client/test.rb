module Offshore
  class Test
    
    def self.current
      @test ||= Test.new
    end
    
    def self.flush
      if @test && @test.run? && !@test.stopped?
        # run again because it crashed in execution
        @test.stop
      end
      @test = nil
    end
    
    def self.start(example)
      flush
      current.start(example)
      current
    end
    
    def self.stop
      current.stop
      current
    end
    

    
    def uuid
      @uid ||= rand(99999999).to_s
    end
    
    def get_name(example)
      name = nil
      name = example.full_description if example.respond_to?(:full_description)
      name ||= "unknown"
      "#{uuid} #{name}"
    end
    
    def run?
      !!@run_example
    end
    
    def stopped?
      !!@stopped
    end

    def start(example=nil)
      raise "already run test: #{get_name(@run_example)}" if @run_example
      @run_example = example
      Offshore.suite.all_hosts!(:test_start, get_name(example))
    end
  
    def stop
      raise "have not run!" unless @run_example
      raise "already stopped!" if @stopped
      @stopped = true
      Offshore.suite.all_hosts!(:test_stop, get_name(@run_example))
    end
  end
end
