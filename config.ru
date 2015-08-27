env = ENV['RACK_ENV'] || 'development'
dev = env == 'development'
Bundler.require(:default, env)
  
# binding.pry

if dev
  require 'logger'
  require 'rack/unreloader'
  
  logger = Logger.new($stdout)
end

# require_relative 'models'

if defined?(Rack::Unreloader)
  Unreloader = Rack::Unreloader.new(:subclasses=>%w'Roda Sequel::Model', :logger=>logger, :reload=>dev){App}
  Unreloader.require('app.rb'){'App'}
end


run(dev ? Unreloader : App.freeze.app)

# require File.expand_path(File.join('..', 'app'),  __FILE__)
# run App.app