
require 'data_mapper'
require 'dm-postgres-adapter'

require_relative 'models/image'

DataMapper.setup(:default, ENV["DATABASE_URL"] || "postgres://splitterstripeservertest.herokuapp.com//splitter_stripe_server_#{ENV['RACK_ENV']}")
DataMapper.finalize
