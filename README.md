One man shortener
=================

This is a Sinatra application written for personal use. It's kinda useful if you have a short personal domain, like http://l-s.me in my case. 

Feature list
------------

* Link minifier (go to `/shorten`, think bit.ly)
* Image store (go to `/upload`, think imgur) 
* Clickthrough statisics on both
* Images have an ultrashort url and a longer, descriptive url - the short url redirects to the long to provide a meaningful filename

Installation
------------

Dependencies: `sinatra`, `haml`, `active_support`, `sequel`, `sqlite3`

First run `ruby create_db.rb` to set up database structure in `db/shortener.sqlite3`.

Then it's Passenger-ready: point DocumentRoot to `public` and enjoy. Or, run it with `ruby shortener.rb` like any Sinatra app.

Default login and password are `admin:admin`. To change this, look in `config.yml`

TODO
----

* Write a screenshot uploader for Linux (sure, I'm biased)


* * *
Contact me at leonid@shevtsov.me
