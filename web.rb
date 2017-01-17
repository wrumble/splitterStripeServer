ENV["RACK_ENV"] ||= "development"
require 'sinatra/base'
require "sinatra/activerecord"
require 'sinatra'
require 'stripe'
require 'dotenv'
require 'json'
require 'encrypted_cookie'
require 'fileutils'
require "carrierwave"
require 'carrierwave/datamapper'
require "carrierwave/orm/activerecord"
require_relative 'models/image'
require_relative 'data_mapper_setup'


Dotenv.load
Stripe.api_key = ENV['STRIPE_TEST_SECRET_KEY']

use Rack::Session::EncryptedCookie, :secret => ENV['SERVER_SECRET']

CarrierWave.configure do |config|
  config.root = File.dirname(__FILE__)
end

get '/' do
  status 200
  return "Splitter's Stripe Server is running."
end

post '/charge' do
  amount = params[:amount].to_i * 100
  fee = (amount * 0.039)/100 + 30
  token = params[:source]
  begin
    charge = Stripe::Charge.create(
    {
      :amount => params[:amount],
      :currency => params[:currency],
      :application_fee => fee,
      :source => token,
      :description => params[:description],
      :destination => params[:stripe_accountID]
    })
  rescue Stripe::StripeError => e
    status 402
    return "Error charging bill splitter: #{e.message}"
  end
  status 200
  return charge.to_json
end

post '/account/create' do
  begin
    account = Stripe::Account.create(
      :managed => true,
      :country => params[:country],
      :email => params[:email],
      :legal_entity => {
                        :first_name => params[:first_name],
                        :last_name => params[:last_name],
                        :dob => {
                                  :day => params[:day],
                                  :month => params[:month],
                                  :year => params[:year]
                                },
                        :address => {
                                      :line1 => params[:line1],
                                      :city => params[:city],
                                      :postal_code => params[:postal_code]
                        },
                        :type => "individual"
      },
      :tos_acceptance => {
                          :date => Time.now.to_i,
                          :ip => request.ip
      }
  )
  rescue Stripe::StripeError => e
    status 402
    return "Error creating managed customer account: #{e.message}"
  end
  status 200
  return account.to_json
end

post '/account/external_account' do
  begin
    account = Stripe::Account.retrieve(params[:stripe_account])
    account.external_accounts.create(
      :external_account => {
                            :object => "bank_account",
                            :country => "US",
                            :currency => "usd",
                            :routing_number => "110000000",
                            :account_number => "000123456789"
                          }
    )
  rescue Stripe::StripeError => e
    status 402
    return "Error adding external account to customer account: #{e.message}"
  end
  status 200
  return account.to_json
end

post '/account/id' do
  begin
    path = File.dirname(__FILE__)
    image = Image.new(file: params[:file])
    image.save
    file = Stripe::FileUpload.create(
      {
        :purpose => params[:purpose],
        :file => File.new("#{path}#{image.file.url}")
      },
      {
        :stripe_account => params[:stripe_account]
      }
    )
  rescue Stripe::StripeError => e
    status 402
    return "Error saving verification id to account: #{e.message}"
  end
  status 200
  return file.to_json
end

post '/account/id/save' do
  begin
    account = Stripe::Account.retrieve(params[:stripe_account])
    account.legal_entity.verification.document = params[:file_id]
    account.save
  rescue Stripe::StripeError => e
    status 402
    return "Error saving verification id to account: #{e.message}"
  end
  status 200
  return account.to_json
end
