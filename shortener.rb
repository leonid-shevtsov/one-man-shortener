$KCODE = 'u'

require 'digest/md5'
require 'rubygems'
require 'sinatra'
require 'sequel'
require 'active_support/all'
require 'haml'
require 'yaml'
require 'mini_magick'

DB = Sequel.sqlite('db/shortener.sqlite3')
CONFIG = YAML.load(File.read('config.yml'))

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
      @auth.credentials[0] == CONFIG['login'] && 
      Digest::MD5.hexdigest(@auth.credentials[1]+CONFIG['salt']) == CONFIG['password_hash']
  end

  def content_type_to_extension(content_type)
    {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/x-png' => 'png',
      'image/gif' => 'gif'
    }[content_type]
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
  protected!
  if record = DB[:urls].where(:slug => params[:slug]).first
    hits = DB[:url_hits].where(:url_id => record[:id]).all
    haml :url_stats, :locals => {:record => record, :hits => hits}
  else
    error 404
  end
end

get '/i/:slug' do
  if (record = DB[:images].where(:slug => params[:slug]).first) && File.exists?("uploads/#{record[:descriptive_slug]}")
    redirect "/uploads/#{record[:descriptive_slug]}", 301
  else
    error 404
  end
end

get '/uploads/:slug' do
  if (record = DB[:images].where(:descriptive_slug => params[:slug]).first) && File.exists?("uploads/#{record[:descriptive_slug]}")
    DB[:image_hits].insert(:image_id => record[:id], :visited_at => Time.now, :ip => request.ip, :referer => request.referer)
    headers 'Content-Type' => record[:content_type], 'Cache-Control' => 'max-age=31536000', 'Expires' => 10.years.from_now.rfc822
    File.read("uploads/#{record[:descriptive_slug]}")
  else
    error 404
  end
end

get '/stats/i/:slug' do
  protected!
  if record = DB[:images].where(:slug => params[:slug]).first
    hits = DB[:image_hits].where(:image_id => record[:id]).all
    haml :image_stats, :locals => {:record => record, :hits => hits}
  else
    error 404
  end
end

post '/stats/i/:slug/destroy' do
  protected!
  if record = DB[:images].where(:slug => params[:slug]).first
    DB[:images].where(:id => record[:id]).delete
    DB[:image_hits].where(:image_id => record[:id]).delete
    File.unlink("uploads/#{record[:descriptive_slug]}")
    redirect '/images', 303
  else
    error 404
  end
end

get '/shorten' do
  protected!
  haml :shorten
end

post '/shorten' do
  protected!
  unless params[:url].blank?
    canonical_url = URI.parse(params[:url]).to_s
    if record = DB[:urls].where(:url => canonical_url).first
      redirect "/stats/s/#{record[:slug]}", 303
    else
      #generate slug
      begin
        slug = rand(36**3).to_s(36) # 50k urls should be enough for anyone
      end while DB[:urls].where(:slug => slug).first
      DB[:urls].insert(:url => canonical_url, :slug => slug, :created_at => Time.now)
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
    content_type = params[:file][:type]
    extension = content_type_to_extension(content_type)
    if extension.blank?
      "Unknown content type #{content_type.tr('<>','[]')}"
    else
      #generate slug
      begin
        slug = rand(36**3).to_s(36) # 50k images should be enough for anyone      
      end while DB[:images].where(['slug LIKE ?',slug+'.%']).first

      slug += "." + extension

      caption = params[:caption].blank? ? File.basename(params[:file][:filename],File.extname(params[:file][:filename])) : params[:caption]
      caption_parameterized = caption.parameterize

      i=nil
      begin
        descriptive_slug = [caption_parameterized,i,extension].compact.join '.'
        i = i.to_i+1
      end while DB[:images].where(:descriptive_slug => descriptive_slug).first

      image = MiniMagick::Image.from_blob(params[:file][:tempfile].read)

      unless params[:noresize]
        image.resize CONFIG['image_dimensions']
      end

      image.write "uploads/#{descriptive_slug}"

      DB[:images].insert(:caption => caption, :slug => slug, :descriptive_slug => descriptive_slug, :content_type => content_type, :created_at => Time.now)

      if params[:format] != 'url'
        redirect "/stats/i/#{slug}", 303
      else
        uri = URI.parse(request.url)
        uri.path = "/i/#{slug}"
        uri.to_s
      end
    end
  else
    haml :upload
  end
end

get '/images' do
  protected!
  images = DB[:images].all
  counts = {}
  DB.fetch('SELECT id, count(*) as cnt from images join image_hits on images.id=image_hits.image_id GROUP BY images.id').do |row|
    counts[row[:id]] = row[:cnt]
  end
  haml :images, :locals => {:images => DB[:images].all}
end
