require 'sinatra'
require 'twilio-ruby'
require 'sinatra/activerecord'
require './config/environments' #database configuration
require './models/entry'
require 'haml'
require 'json'
require 'csv'
require 'chartkick'
require 'sinatra/flash'

use Rack::Session::Cookie, :expire_after => 3600 # In seconds

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

get '/login' do
  @title = "Login"
  haml :login
end

get_or_post '/post_login' do
  flash[:password] = "test" + ENV['PASSWORD']
  if params[:password] == ENV['PASSWORD']
    session[:login] = true
    redirect '/'
  else
    flash[:error] = "Wrong password"
    redirect '/login'
  end
end

get_or_post '/logout' do 
  session[:login] = false
  redirect '/'
end

# Displays graphs for current, voltage, and temperature
get '/filter' do
  if session[:login]
    @title = "Filter"
    @entries = Entry.all
    @temperature = Array.new

    @entries.each do |e|
      @temps = (e.temperature).split(',')
      i = 1
      @temps.each do |t|
        t = t.strip
        if @temperature.size < i then
          @data = Hash.new
          @data["name"] = "Temperature #{i}"
          @data["data"] = Hash.new
          @temperature << @data
        end
        if (t != "x")
          (@temperature[i-1]["data"])[e.date_time] = t.to_f
        end
        i += 1
      end
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
  else
    redirect '/login'
  end
end

get '/manualAdd' do 
  if session[:login]
    @title = "Add"
    haml :manualAdd
  else 
    redirect '/login'
  end
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

get '/downloadcsv' do
  @title = "Download CSV"
  haml :download
  date1 = params[:date1]
  date2 = params[:date2]
  temperature = params[:temperature]
  current = params[:current]
  voltage = params[:voltage]
  @entries = Entry.all

  if (date1 == nil or date2 == nil or date1 > date2)
    flash[:error] = "Please enter a valid date range"
    redirect '/data'
  end 

  CSV.open('public/sample.csv', 'wb') do |csv|
    csv << ["Date 1", date1, "Date 2", date2]
    header = Array.new
    header << "Date"
    if current then header << "Current" end
    if voltage then header << "Voltage" end
    if temperature then header << "Temperature" end
    csv << header
    @entries.each do |e|
      line = Array.new
      line << e.date_time
      if current then line << e.current end
      if voltage then line << e.voltage end
      if temperature 
        e.temperature.split(',').each do |t|
          line << t.strip
        end
      end
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
  if session[:login]
    @title = "Entries"
    @entries = Entry.all
    haml :entries
  else 
    redirect '/login'
  end
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
  if session[:login]
    @title = "Download Data"
    haml :download
  else 
    redirect '/login'
  end
end