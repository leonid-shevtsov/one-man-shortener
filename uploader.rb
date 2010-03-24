#!/usr/bin/ruby
require 'optparse'
require 'tmpdir'
require 'net/http'
require 'uri'
require 'base64'

uploader_uri = URI.parse('http://localhost:9393/upload')
uploader_user = 'admin'
uploader_password = 'admin'

options = {
  :mode => :screen
}

scrot_params = {
  :screen => '',
  :window => '--focused --border',
  :area => '--select'
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{ARGV[0]} [options]"

  opts.on("","--screen", "Shoot screen") do
    options[:mode] = :screen
  end
  opts.on("", "--window", "Shoot window") do
    options[:mode] = :window
  end
  opts.on("", "--area", "Shoot area") do
    options[:mode] = :area
  end
  opts.on("", "--file FILENAME", "Upload a file") do |filename|
    options[:mode] = :file
    options[:filename] = filename
  end
  opts.on("", "--caption CAPTION", "Caption") do |caption|
    options[:caption] = caption
  end
end.parse!

if options[:mode] == :file
  filename = options[:filename]

  default_caption = File.basename(filename,File.extname(filename))
else 
  # need a screenshot
  if options[:mode] == :area
    `notify-send "Waiting for area selection (anykey to abort)"`
  end

  filename = "#{Dir.tmpdir}/screenshot_#{Time.now.to_i}.png"
  filename = "screenshot_#{Time.now.to_i}.png"

  `scrot #{scrot_params[options[:mode]]} #{filename}`

  `notify-send "Scrot aborted"` and exit unless File.exists?(filename)
  
  default_caption = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
end


caption = options[:caption] || `zenity --entry --entry-text="#{default_caption}" --text="Caption" --title="caption"`.strip

# now upload
#
def text_to_multipart(key,value)
  return "Content-Disposition: form-data; name=\"#{URI::escape(key)}\"\r\n" + 
         "\r\n" + 
         "#{value}\r\n"
end

def file_to_multipart(key,filename,mime_type,content)
  return "Content-Disposition: form-data; name=\"#{URI::escape(key)}\"; filename=\"#{filename}\"\r\n" +
         "Content-Transfer-Encoding: binary\r\n" +
         "Content-Type: #{mime_type}\r\n" + 
         "\r\n" + 
         "#{content}\r\n"
end

params = [ 
  file_to_multipart('file',File.basename(filename),'image/png',File.read(filename)),
  text_to_multipart('caption', caption),
  text_to_multipart('format','url')
]
params << text_to_multipart('noresize','1') unless options[:mode] == :file


boundary = '349832898984244898448024464570528145'
query = params.collect {|p| '--' + boundary + "\r\n" + p}.join('') + "--" + boundary + "--\r\n"

`notify-send "Uploading image..."`

response = Net::HTTP.
  start(uploader_uri.host,uploader_uri.port).
  post2(uploader_uri.path, query, "Content-type" => "multipart/form-data; boundary=" + boundary, "Authorization" => "Basic #{Base64.encode64("#{uploader_user}:#{uploader_password}")}")


url = response.body

if options[:mode] != :file
  if url[0,7] != 'http://' 
    `zenity --error --text="Error uploading screenshot.\nYou can find the file at #{filename}"` and exit 
  else
    File.unlink(filename)
  end
end

unless system("zenity --entry --entry-text=\"#{url}\" --title=\"Image URL\" --text=\"Click \\\"Cancel\\\" to go to the stats page.\"")
  `xdg-open #{url.gsub('/i/','/stats/i/')}`
end
