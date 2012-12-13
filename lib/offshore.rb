require "offshore/version"

module Offshore
  extend self
  
  WAIT_CODE = 499
  
  def suite
    @suite ||= Suite.new
  end
  
  def test
    if @test && @test.run?
      # run again because it crashed in execution
      @test.failed
    end
    @test ||= Test.new
  end
  
  protected
    
  def internal_test_ended
    # called from test.failed and test.stop
    @test = nil
  end
end

require "offshore/client"
require "offshore/server"