# Offshore

For when you need a remote factory.
Let's say you love testing, but your app heavily depends on another app and it's data in a certain format. You have API and/or database access to this data.

Offshore allows you use the factories of that app within your test suite as well as adds transactional support to the database of that app so that each test starts with the same fixtures.

#### Notes

* For now, this only works on MySQL databases
* Redis is needed to run as well

## Server

The server app is the one with the factories and the database that your app needs to work.
For Rails, add this to your Gemfile:

    group :test do
      gem 'offshore'
    end
    
You might need something like this to your test.rb application config:

    Offshore.redis = "localhost:6379"

Then run something like this on the command line

    OFFSHORE=true rails s thin -e test -p 6001

In you want it anything but blank, you must create a rake task called offshore:seed that creates the test database referenced in the database.yml file in the test environment.
Something like this would work.

    namespace :offshore do
      task :preload do
        ENV['RAILS_ENV'] = "test"
      end
      task :setup => :environment
  
      desc "seeds the db for offshore gem"
      task :seed do
        Rake::Task['db:migrate'].invoke
        Rake::Task['db:test:prepare'].invoke
        Rake::Task['db:seed'].invoke
      end
    end

The :preload and :setup steps will be invoked in that order before your :seed call. They are actually unnecessary here, but shown in case you have something more complex to do.

#### Notes

* For other Rack apps, you should be able to use Offshore::Middleware directly.
* This middleware is included automatically in Rails via Railties.
* The server is meant to be a singular resource accessed by many test threads (parallelization of tests). It accomplishes this through a mutex and polling its availability.



## Client

The client app is the one running the tests.

The same thing in the Gemfile:

    group :test do
      gem 'offshore'
    end
    
The Rspec config looks likes this:

    config.before(:suite) do
      Offshore.suite.start(:host => "localhost", :port => 4111)
    end

    config.before(:each) do
      Offshore.test.start(example)
    end

    config.after(:each) do
      Offshore.test.stop
    end

    config.after(:suite) do
      Offshore.suite.stop
    end

Then in your test you can do:

    user = FactoryOffshore.create(:user, :first_name => "Johnny")
    user.first_name.should == "Johnny"
    user.class.should == ::User

This assumes that you have a class by the same name the the :user factory made from the server that responds to find() with the id created on the server.

You can send :snapshot => false to Offshore.suite.start to prevent rolling back before the test. 
Note, this will leave your suite in a somewhat unpredictable state especially when you consider there are other suites that might be rolling that database back. 
However, this may be preferable if your database is very large. On small (50 tables / 1000 rows) databases, the difference in time seems to be noise. Some efforts are taken (checksum) to not rollback if the test did not change the database.


#### Notes

* You can also make API requests.
* You get a fresh database each time by default.

## TODO

* Use binlogs if enabled for even faster MySQL rollback
* Configure custom lookups for the hash returned with the created data
* Configure custom paths (defaults to /offshore_tests now)
* Anything else need to be cleared out each test? i.e. redis, memcache, etc
* Other DB support
* Other MySQL adapter support

