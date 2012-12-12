class FactoryOffshore
  def self.create(*args)
    host = Offshore.suite.default
    host.factory_create(*args)
  end
  
  # TODO: multiple hosts  
end