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
