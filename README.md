Lightweight backend server for Splitter iOS app in ruby with sinatra.

Utilises the Stripe gem to connect two users and allow the transfering of money using Stripe Connect.

Currently has 5 post requests to deal with:

- Adding a Stripe Connect Managed account. --- ```/account```
- Adding a external bank account to withdraw funds from the managed account. --- ```/account/external_account```
- Adding verification photo id to the Managed account. --- ```/account/id```
- Saving verification photo id using file_id from ```account/id``` response. --- ```/account/id/save```
- Charging a users card in which a percentage goes to the Splitter account and the rest to the app owners Stripe Connect Managed account. --- ```/charge```

It has one get request ```/``` which is purely to show if the server is running correctly.

It is currently set to run in test mode. To run in test mode on heroku run:

```git clone git@github.com:wrumble/splitterStripeServer.git```

```cd splitterStripeServer```

```git init```

```git add .```

```git commit -m"initial commit"```

```heroku create <whatever server name you want>```

You then need to update ```data_mapper_setup.rb``` and replace:

```postgres://splitterstripeservertest.herokuapp.com//splitter_stripe_server_```

with:

```postgres://<whatever heroku server name you set>.herokuapp.com//splitter_stripe_server_```

Then run:

```git push heroku master```

```heroku run rake db:auto_migrate```


You then need to sign up to Stripe and create a managed account. From the dashboard you can then get a publishable key which you will need for your app when running client and a test secret key which you will then add to heroku's environment variables by running:


```heroku config:set STRIPE_TEST_SECRET_KEY=WhateverYourStripeSecretKeyIs```

```heroku config:set SERVER_SECRET=WhateverYouWantAsItsYourEncryptedCookieSecret```


Now if you go to https://<whatever server name you set>.herokuapp.com/ you should see:


```Splitter's Stripe Server is running.```


To go live you must do as above but using your live stripe keys instead of test keys, you will also want to change the pre filled test account details in the ```/account/external_account``` request to whatever params you pass from your client side app. These will change to:


```:country =>  params[:country]```

```:currency => params[:currency]```

```:routing_number => params[:sort_code]```

```:account_number => params[:account_number]```

```:object => "bank_account"``` can stay as it is.


That should be it! let me know of any updates, errors refactors etc :)
