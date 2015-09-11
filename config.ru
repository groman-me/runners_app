env = ENV['RACK_ENV'] || 'development'
dev = env == 'development'
Bundler.require(:default, env)

if dev
  require 'logger'
  require 'rack/unreloader'

  logger = Logger.new($stdout)
end

if defined?(Rack::Unreloader)
  Unreloader = Rack::Unreloader.new(:subclasses=>%w'Roda Sequel::Model', :logger=>logger, :reload=>dev){App}
  Unreloader.require('app.rb'){'App'}
else
  require_relative 'app.rb'
end


run(dev ? Unreloader : App.freeze.app)
