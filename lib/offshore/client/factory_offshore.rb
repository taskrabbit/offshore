class FactoryOffshore
  # return the object
  def self.create(*args)
    host = Offshore.suite.default
    host.factory_create(*args)
  end
  
  # return the id
  def self.create_id(*args)
    host = Offshore.suite.default
    host.factory_create_id(*args)
  end
  
  # TODO: multiple hosts  
end