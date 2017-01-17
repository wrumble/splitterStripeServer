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
```git push heroku master```
```heroku run rake db:auto_migrate```

You then need to sign up to Stripe and create a managed account. From the dashboard you can then get a publishable key which you will need for your app when running client and a secret key which you will then add to heroku's environment variables by running:

```heroku config:set STRIPE_TEST_SECRET_KEY=WhateverYourStripeSecretKeyIs SERVER_SECRET=ThisCanBeAnyThingYouWantItsYourEncryptedCookieSecret```
