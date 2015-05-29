require 'sinatra'
require 'twilio-ruby'
require 'sinatra/activerecord'
require './config/environments' #database configuration
require './models/entry'
require 'haml'
require 'json'
require 'csv'
require 'chartkick'

# A hack around multiple routes in Sinatra
def get_or_post(path, opts={}, &block)
  get(path, opts, &block)
  post(path, opts, &block)
end

# Home page and reference
get '/' do
  @title = "Home"
  haml :home
end

get '/filter' do
  @title = "Filter"
  @entries = Entry.all
  haml :filter
end

get '/temperature' do
  @entries = Entry.all
  @temperature = Hash.new
  @entries.each do |e|
    @temperature[e.date_time] = (e.temperature).split(',')
  end
  content_type 'application/json'
  @temperature.to_json
end

get_or_post '/delete' do
  p = Entry.where(id: params[:id]).first
  p.destroy
  redirect '/entries'
end

get '/downloadcsv2' do
  @title = "Download CSV"
  haml :download
  date1 = params[:date1]
  date2 = params[:date2]
  temperature = params[:temperature]
  current = params[:current]
  voltage = params[:voltage]
  @entries = Entry.all

  CSV.open('public/sample.csv', 'wb') do |csv|
    csv << ["Date 1", date1, "Date 2", date2]
    header = Array.new
    header << "Date"
    if temperature then header << "Temperature" end
    if current then header << "Current" end
    if voltage then header << "Voltage" end
    csv << header
    @entries.each do |e|
      line = Array.new
      line << e.date_time
      if temperature then line << e.temperature end
      if current then line << e.current end
      if voltage then line << e.voltage end
      csv << line
    end
  end 

  send_file 'public/sample.csv', :disposition => "attachment"
end 

# SMS Request URL
get_or_post '/sms/?' do
  sender = params[:From]
  message = params[:Body]
  parse = message.split(';')
  
  @entry = Entry.new(:message => message, :sender => sender, :temperature => parse[0].strip, :current => parse[1].strip, :voltage => parse[2].strip, :date_time => DateTime.now)
  if @entry.save
    responseText = "Message successfully added!"
  else 
    responseText = "There was an error"
  end

  response = Twilio::TwiML::Response.new do |r|
    r.Sms responseText
  end
  response.text
end

get '/entries' do
  @title = "Entries"
  @entries = Entry.all
  haml :entries
end

get '/contact' do
  @title = "Contact Us"
  haml :contact
end

get '/about' do
  @title = "About Us"
  haml :about
end

get '/data' do
  @title = "Download Data"
  haml :download
end