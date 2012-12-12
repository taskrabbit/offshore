# Offshore

For when you need a remote factory.
Let's say you love testing, but your app heavily depends on another app and it's data in a certain format. You have API and/or database access to this data.

Offshore allows you use the factories of that app within your test suite as well as adds transactional support to the database of that app so that each test starts with the same fixtures.


## Server

The server app is the one with the factories and the database that your app needs to work.
For Rails, add this to your Gemfile:

    group :test do
      gem 'offshore'
    end

Then run something like this on the command line

    rails s thin -e test -p 4111

You need to include an SQL file to load in with in this app


#### Notes

* For other Rack apps, you should be able to use Offshore::Middleware directly.
* This middleware is included automatically in Rails via Railties.
* The server is meant to be a singular resource accessed by many test threads (parallelization of tests). It accomplishes this through a mutex and queueing.
* Redis is required on this app.


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
      Offshore.test.start
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


#### Notes

* You can also make API requests.
* You get a fresh database each time.


## TODO

* Reset the db on each test run
* Locking mechanism to provide mutex access to resource
* Configure custom lookups for the hash returned with the created data
* Configure custom paths (defaults to /offshore_tests now)
* Anything else need to be cleared out each test? i.e. redis, memcache, etc

