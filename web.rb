require 'sinatra'
require 'stripe'
require 'dotenv'
require 'json'
require 'encrypted_cookie'

Dotenv.load

Stripe.api_key = ENV['STRIPE_TEST_SECRET_KEY']

use Rack::Session::EncryptedCookie,

  :secret =>  ENV['SERVER_SECRET'] # Actually use something secret here!

get '/' do
  status 200
  return "Splitter Stripe Server is running."
end

post '/charge' do
  authenticate!
  # Get the credit card details submitted by the form
  source = params[:source]

  # Create the charge on Stripe's servers - this will charge the user's card
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

get '/customer' do
  authenticate!
  status 200
  content_type :json
  @customer.to_json
end

# get "/customer" do
#   begin
#     customer_id = "..." # Load the Stripe Customer ID for your logged in user
#     customer = Stripe::Customer.retrieve(customer_id)
#   rescue Stripe::StripeError => e
#     status 402
#     return "Error retrieving customer: #{e.message}"
#   end
#   status 200
#   content_type :json
#   customer.to_json
# end

post '/customer/charge' do
  authenticate!
  source = params[:source]

  # Adds the token to the customer's sources
  begin
    @customer.sources.create({:source => source})
  rescue Stripe::StripeError => e
    status 402
    return "Error adding token to customer: #{e.message}"
  end
  charge = Stripe::Charge.create(
    :amount => params[:amount], # this number should be in cents
    :currency => params[:currency],
    :customer => @customer.id,
    :source => source,
    :description => params[:description]
  )
  status 200
  return "Successfully added source."
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
