require 'rubygems'
require 'sinatra'

Sinatra::Base.set(:run, false)
Sinatra::Base.set(:env, ENV['RACK_ENV'])

require 'shortener'
run Sinatra::Application
