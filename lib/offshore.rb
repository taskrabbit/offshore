require "offshore/version"

module Offshore
  extend self
  
  WAIT_CODE = 499
  
  def suite
    @suite ||= Suite.new
  end
  
  def test
    Offshore::Test
  end

  def enable!
    @enabled = true
  end

  def enabled?
    !!@enabled
  end

  def disable!
    @enabled = false
  end
end

require "offshore/client"
require "offshore/server"