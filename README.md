One man shortener
=================

This is a Sinatra application written for personal use. It's kinda useful if you have a short personal domain, like http://l-s.me in my case. 

Feature list
------------

* Link minifier (go to `/shorten`, think bit.ly)
* Image store (go to `/upload`, think imgur) 
* Clickthrough statisics on both
* Images have an ultrashort url and a longer, descriptive url - the short url redirects to the long to provide a meaningful filename
* Automatical image resizing (using `mini_magick`)
* Image uploader for Linux (using `scrot` + `zenity` + `notify-send`)

Installation
------------

Dependencies: `sinatra`, `haml`, `active_support`, `sequel`, `sqlite3`, `mini_magick`

First run `ruby create_db.rb` to set up database structure in `db/shortener.sqlite3`.

Then it's Passenger-ready: point DocumentRoot to `public` and enjoy. Or, run it with `ruby shortener.rb` like any Sinatra app.

Default login and password are `admin:admin`. To change this, look in `config.yml`

Uploader installation
---------------------

To use the uploader, just move it somewhere convenient and change URL, username and password at the head of the script.

TODO
----

Nothing for now.

* * *
Contact me at leonid@shevtsov.me
