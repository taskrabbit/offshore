namespace :offshore do
  task :setup
  task :seed
  
  task :preload do
    require "offshore"
  end
  
  task :unlock => [:preload, :setup] do
    Offshore::Database.unlock
  end
  
  task :shutdown => [:preload, :setup] do
    Offshore::Database.shutdown
  end
  
  task :startup => [:preload, :setup] do
    Offshore::Database.startup(false)
  end
  
  desc "Setup will configure a resque task to run before resque:work"
  task :seed_and_unlock => [ :preload, :setup, :seed, :unlock ]
end
