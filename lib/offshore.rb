require "offshore/version"

module Offshore
  extend self
  
  def suite
    @suite ||= Suite.new
  end
  
  def test
    @test ||= Test.new
  end
  
  protected
  
  def internal_test_ended
    @test = nil
  end
end

require "offshore/client"
require "offshore/server"