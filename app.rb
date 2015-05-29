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
  # @temperature = Hash.new
  # @entries.each do |e|
  #   @temperature[e.date_time] = (e.temperature).split(',')[0].to_f
  # end
  @temperature = Array.new

  (1..5).each do |i|
    @data = Hash.new
    @data["name"] = "Temperature #{i}"
    @data["data"] = Hash.new
    @temperature << @data
  end

  @entries.each do |e|
    @temps = (e.temperature).split(',')
    i = 0
    @temps.each do |t|
      (@temperature[i]["data"])[e.date_time] = t.to_f
      i += 1
    end
    # @temperature[e.date_time] = (e.temperature).split(',')[0].to_f
  end

  @current = Hash.new
  @entries.each do |e|
    @current[e.date_time] = e.current.to_f
  end

  @voltage = Hash.new
  @entries.each do |e|
    @voltage[e.date_time] = e.voltage.to_f
  end

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

get '/manualAdd' do 
  @title = "Add"
  haml :manualAdd
end

get_or_post '/addEntry' do
  sender = params[:from]
  message = params[:body]
  parse = message.split(';')
  
  @entry = Entry.new(:message => message, :sender => sender, :temperature => parse[0].strip, :current => parse[1].strip, :voltage => parse[2].strip, :date_time => DateTime.now)
  @entry.save
  redirect '/entries'
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