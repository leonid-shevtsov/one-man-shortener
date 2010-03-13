require 'digest/md5'
require 'rubygems'
require 'sinatra'
require 'sequel'
require 'active_support'
require 'haml'

AUTH_USER = 'admin'
AUTH_PASSWORD_HASH = '72b155508c6b12d17828d20d53662080'
AUTH_SALT = 'sgawdgbsdghfsghdf'

DB = Sequel.sqlite('db/shortener.db')

helpers do
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Admin")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && 
      @auth.basic? && 
      @auth.credentials && 
      @auth.credentials[0] == AUTH_USER && 
      Digest::MD5.hexdigest(@auth.credentials[1]+AUTH_SALT) == AUTH_PASSWORD_HASH
  end
end

get '/' do
  haml :index
end

get '/s/:slug' do
  if record = DB[:urls].where(:slug => params[:slug]).first
    DB[:url_hits].insert(:url_id => record[:id], :visited_at => Time.now, :ip => request.ip, :referer => request.referer)
    redirect record[:url], 301
  else
    error 404
  end
end

get '/stats/s/:slug' do
  if record = DB[:urls].where(:slug => params[:slug]).first
    hits = DB[:url_hits].where(:url_id => record[:id]).all
    haml :url_stats, :locals => {:record => record, :hits => hits}
  else
    error 404
  end
end

get '/i/:slug' do
  "get uploaded image"
end

get '/stats/i/:slug' do
  if record = DB[:images].where(:slug => params[:slug]).first
    hits = DB[:image_hits].where(:image_id => record[:id]).all
    haml :image_stats, :locals => {:record => record, :hits => hits}
  else
    error 404
  end
end

get '/shorten' do
  protected!
  haml :shorten
end

post '/shorten' do
  unless params[:url].blank?
    canonical_url = URI.parse(params[:url]).to_s
    if record = DB[:urls].where(:url => canonical_url).first
      redirect "/stats/s/#{record[:slug]}", 303
    else
      #generate slug
      begin
        slug = rand(36**3).to_s(36) # 50k urls should be enough for anyone
      end while DB[:urls].where(:slug => slug).first
      DB[:urls].insert(:url => canonical_url, :slug => slug)
      redirect "/stats/s/#{slug}", 303
    end
  else
    haml :shorten
  end
end

get '/urls' do
  protected!
  haml :urls, :locals => {:urls => DB[:urls].all}
end

get '/upload' do
  protected!
  haml :upload
end

post '/upload' do
  protected!
  if params[:file] && params[:file][:tempfile]
    tmpfile = params[:file][:tempfile]
    tmpfile.read
  else
    haml :upload
  end
end

get '/images' do
  protected!
  haml :images
end
