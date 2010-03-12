require 'rubygems'
require 'sequel'

db = Sequel.sqlite('db/shortener.db')

db.create_table :urls do
  primary_key :id
  String :url
  String :slug
  Time :created_at
end

db.create_table :images do
  primary_key :id
  String :filename
  String :slug
  String :caption
  Time :created_at
end

db.create_table :url_hits do
  primary_key :id
  foreign_key :url_id, :urls
  String :ip, :size => 15
  String :referer
  Time :visited_at
end

db.create_table :image_hits do
  primary_key :id
  foreign_key :image_id, :images
  Time :visited_at
  String :ip, :size => 15
  String :referer
end

