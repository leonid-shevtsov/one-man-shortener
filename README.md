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
* ZScreen compatibility

Installation
------------

With bundler: 

`bundle install`

Otherwise, install the gems from `Gemfile` manually.

First run `bundle exec ruby create_db.rb` to set up database structure in `db/shortener.sqlite3`.

Then it's Passenger-ready: point DocumentRoot to `public` and enjoy. Or, run it with `ruby shortener.rb` like any Sinatra app.

Default login and password are `admin:admin`. To change this, look in `config.yml`

Uploader installation
---------------------

The uploader is only dependant only Ruby's stdlib. Nifty!

Configure URL, username and password at the head of the script. Then use.

ZScreen installation
--------------------

* Specify an `uploader_key` in the `config.yml` file.
* Go to `Image hosting => Custom image uploaders` in ZScreen
* Click `Import...` and pick the `one-man-shortener.zihs` file from this repository
* In the `Arguments` fields, enter `uploader_key` in the first and your key in the second. Click `Add`
* Change the 'Upload URL' to reflect your host.
* Click `Update` in the top left corner, under the uploader name
* You're done! Click `Test Upload` to test it.


TODO
----

Nothing for now.

* * *
Contact me at leonid@shevtsov.me
