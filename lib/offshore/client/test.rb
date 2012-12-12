module Offshore
  class Test
  
    def start
      Offshore.suite.all_hosts!(:test_start)
    end
  
    def stop
      Offshore.suite.all_hosts!(:test_stop)
      Offshore.send(:internal_test_ended)
    end
  
  end
end
