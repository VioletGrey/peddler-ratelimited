Gem::Specification.new do |gem|
  gem.name        = 'peddler-ratelimited'
  gem.version     = '1.0.7'
  gem.date        = '2017-08-10'
  gem.summary     = "RateLimited Peddler!"
  gem.description = "Rate limitting Peddler"
  gem.authors     = ["Vahak Matavosian"]
  gem.email       = 'vahak@violetgrey.com'
  gem.files       =  Dir.glob('lib/**/*') + %w[LICENSE README.md]
  gem.homepage    = 'http://rubygems.org/gems/peddler-ratelimited'
  gem.license       = 'MIT'

  gem.require_paths = ['lib']

  gem.add_dependency 'peddler', '1.6.1'
  gem.add_dependency 'ratelimit', '~> 1.0'
  gem.add_dependency 'resque', '~> 1.27'
  gem.add_dependency 'resque-scheduler', '~> 4.3'
  gem.add_dependency 'resque-retry', '~> 1.5'
  gem.add_dependency 'simple_spark', '~> 1.0'

  gem.required_ruby_version = '>= 2.0'

end

