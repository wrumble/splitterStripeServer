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

use Rack::Session::EncryptedCookie,
  :secret => ENV['SERVER_SECRET']

CarrierWave.configure do |config|
  config.root = File.dirname(__FILE__) + "/public"
end

get '/' do
  status 200
  return "Splitter's Stripe Server is running."
end

post '/charge' do
  authenticate!
  # Get the credit card details submitted by the form
  source = params[:source]

  # Create the charge on Stripe's servers - this will charge the user's card
  begin
    charge = Stripe::Charge.create(
      :amount => params[:amount],
      :currency => params[:currency],
      :customer => @customer.id,
      :source => source,
      :description => params[:description]
    )
  rescue Stripe::StripeError => e
    status 402
    return "Error creating charge: #{e.message}"
  end

  status 200
  return "Charge successfully created"
end

get '/customer' do
  authenticate!
  status 200
  content_type :json
  @customer.to_json
end

post '/account/create' do
  begin
    p params
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
  p account
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
    account.external_account.object = "bank_account"
    account.external_account.country = 'US'
    account.external_account.currency = "usd"
    account.external_account.account_number = "110000000"
    account.external_account.routing_number = "000123456789"
    account.save
  rescue Stripe::StripeError => e
    status 402
    return "Error adding external account to customer account: #{e.message}"
  end
  status 200
  return account.to_json
end

post '/account/id' do
  begin
    path = File.dirname(__FILE__) + "/public"
    image = Image.new(file: params[:file][:tempfile])
    image.save
    file = Stripe::FileUpload.create(
      {
        :purpose => params[:purpose],
        :file => File.new(path + image.file.url)
      },
      {
        :stripe_account => params[:stripe_account]
      }
    )
    image.destroy
  rescue Stripe::StripeError => e
    status 402
    return "Error saving verification id to account: #{e.message}"
  end
  status 200
  return file.to_json
end

post '/account/id' do
  account = Stripe::Account.retrieve(params[:stripe_account])
  account.legal_entity.verification.document = params[:file_id]
  account.save
  return account.to_json
end

post '/customer/sources' do
  authenticate!
  source = params[:source]

  # Adds the token to the customer's sources
  begin
    @customer.sources.create({:source => source})
  rescue Stripe::StripeError => e
    status 402
    return "Error adding token to customer: #{e.message}"
  end

  begin
    charge = Stripe::Charge.create(
      :amount => params[:amount], # this number should be in cents
      :currency => params[:currency],
      :customer => @customer.id,
      :source => source,
      :description => params[:description]
    )
  rescue Stripe::StripeError => e
    status 402
    return "Error creating charge: #{e.message}"
  end

  status 200
  return "Charge successfully created"
end

post '/customer/default_source' do
  authenticate!
  source = params[:source]

  # Sets the customer's default source
  begin
    @customer.default_source = source
    @customer.save
  rescue Stripe::StripeError => e
    status 402
    return "Error selecting default source: #{e.message}"
  end

  status 200
  return "Successfully selected default source."
end

def authenticate!
  # This code simulates "loading the Stripe customer for your current session".
  # Your own logic will likely look very different.
  return @customer if @customer
  if session.has_key?(:customer_id)
    customer_id = session[:customer_id]
    begin
      @customer = Stripe::Customer.retrieve(customer_id)
    rescue Stripe::InvalidRequestError
    end
  else
    begin
      @customer = Stripe::Customer.create(:description => "iOS SDK example customer")
    rescue Stripe::InvalidRequestError
    end
    session[:customer_id] = @customer.id
  end
  @customer
end

# This endpoint is used by the Obj-C example to complete a charge.
post '/charge_card' do
  # Get the credit card details submitted by the form
  token = params[:stripe_token]

  # Create the charge on Stripe's servers - this will charge the user's card
  begin
    charge = Stripe::Charge.create(
      :amount => params[:amount], # this number should be in cents
      :currency => params[:currency],
      :card => token,
      :description => params[:description]
    )
  rescue Stripe::StripeError => e
    status 402
    return "Error creating charge: #{e.message}"
  end

  status 200
  return "Charge successfully created"
end
