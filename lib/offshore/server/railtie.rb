module Offshore
  class Railtie < Rails::Railtie
    config.app_middleware.use 'Offshore::Middleware'
  end
end