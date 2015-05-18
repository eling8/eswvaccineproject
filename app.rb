require 'sinatra'
require 'twilio-ruby'
require 'sinatra/activerecord'
require './config/environments' #database configuration
require './models/entry'
require 'haml'

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
  haml :filter
end

get '/temperature' do
  @entries = Entry.all
  @temperature = Hash.new
  @entries.each do |e|
    @temperature[e.date_time] = e.temperature.split(',')
  end
  render :json => @temperature
end

get '/current' do
  @entries = Entry.select(:temperature, :date_time)
  @current = Hash.new
  @entries.each do |e|
    @current[e.date_time] = e.current
  end
  render :json => @current
end

get '/voltage' do
  @entries = Entry.select(:temperature, :date_time)
  @voltage = Hash.new
  @entries.each do |e|
    @voltage[e.date_time] = e.voltage
  end
  render :json => @voltage
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