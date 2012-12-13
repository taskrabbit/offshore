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
  
  task :unlock => [:preload, :setup] do
    Offshore::Database.unlock
  end
  
  task :shutdown => [:preload, :setup] do
    Offshore::Database.shutdown
  end
  
  task :startup => [:preload, :setup] do
    Offshore::Database.startup(false)
  end
  
  task :reset => [:preload, :setup] do
    Offshore::Database.reset
  end
  
  task :seed_schema => [ :preload, :setup, :seed, :schema_snapshot ]
  
end
