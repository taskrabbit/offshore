namespace :offshore do
  task :setup
  task :seed
  
  task :preload do
    require "offshore"
  end
  
  task :schema_snapshot => [:preload, :setup] do
    Offshore::Database.schema_snapshot
  end
  
  task :schema_rollback => [:preload, :setup] do
    Offshore::Database.snapshoter.rollback
  end
  
  desc "Unlock the database"
  task :unlock => [:preload, :setup] do
    Offshore::Database.unlock
  end
  
  task :shutdown => [:preload, :setup] do
    Offshore::Database.shutdown
  end
  
  task :startup => [:preload, :setup, :seed_schema] do
    Offshore::Database.startup
  end
  
  desc "Reset the db"
  task :reset => [:preload, :setup] do
    Offshore::Database.reset
  end
  
  desc "seed the databse if needed"
  task :seed_schema => [ :preload, :setup, :seed, :schema_snapshot ]
  
end
