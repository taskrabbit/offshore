# -*- encoding: utf-8 -*-
require File.expand_path('../lib/offshore/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Brian Leonard"]
  gem.email         = ["brian@bleonard.com"]
  gem.description   = %q{For handling remote factories and tests}
  gem.summary       = %q{For handling remote factories and tests}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "offshore"
  gem.require_paths = ["lib"]
  gem.version       = Offshore::VERSION
  
  gem.add_dependency "multi_json"
  gem.add_dependency "faraday"
  gem.add_dependency "redis"
  gem.add_dependency "redis-namespace"
  gem.add_dependency "mysql2"
end
