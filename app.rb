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

use Rack::Session::Cookie, :expire_after => 18000 # In seconds

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
defaultNumPoints = 10 #This is the number of points that the graph will display on default
get_or_post '/filter' do
  if session[:login]
    @title = "Filter"
    @entries = Entry.all
    @temperature = Array.new

    @showGraph = true
    @dates = false
    if params[:date1] then @dates = true end

    if @dates 
      defaultNumPoints = 1000000
      @date1 = Date.parse(params[:date1])
      @date2 = Date.parse(params[:date2])
      @time1 = Time.parse(params[:time1])
      @time2 = Time.parse(params[:time2])

      @dt1 = @date1.to_datetime + @time1.seconds_since_midnight.seconds
      @dt2 = @date2.to_datetime + @time2.seconds_since_midnight.seconds
    end

    if @showGraph 
      numPoints = 1
      @entries.reverse.each do |e|
        if numPoints > defaultNumPoints
          break
        end
        numPoints = numPoints+1
        if !@dates || e.date_time >= @dt1 && e.date_time <= @dt2
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
      end

      @current = Hash.new
      numPoints = 1
      @entries.reverse.each do |e|
        if(numPoints > defaultNumPoints)
          break
        end
        numPoints = numPoints + 1
        if !@dates || e.date_time >= @dt1 && e.date_time <= @dt2
          @current[e.date_time] = e.current.to_f
        end
      end

      @voltage = Hash.new
      numPoints = 1
      @entries.reverse.each do |e|
        if(numPoints > defaultNumPoints)
          break
        end
        numPoints = numPoints + 1
        if !@dates || e.date_time >= @dt1 && e.date_time <= @dt2
          @voltage[e.date_time] = e.voltage.to_f
        end
      end
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
  date1 = Date.parse(params[:date1])
  date2 = Date.parse(params[:date2])
  time1 = Time.parse(params[:time1])
  time2 = Time.parse(params[:time2])
  temperature = params[:temperature]
  current = params[:current]
  voltage = params[:voltage]
  @entries = Entry.all

  #if params[:date1] == "2015-05-29" or params[:date1] == nil 
   # flash[:error] = "Please enter a valid date range"
    #redirect '/data' 
  #end
  if time1
    time1 = "00:00:00"
  end
  dt1 = date1.to_datetime + time1.seconds_since_midnight.seconds
  dt2 = date2.to_datetime + time2.seconds_since_midnight.seconds
  # dt1 = DateTime.new(date1.year, date1.month, date1.day, time1.hour, time1.min, time1.sec)
  # dt2 = DateTime.new(date2.year, date2.month, date2.day, time2.hour, time2.min, time2.sec)

  CSV.open('public/data.csv', 'wb') do |csv|
    csv << ["Date 1", params[:date1] << 'T'<< params[:time1], "Date 2", params[:date2] << 'T'<< params[:time2]]
    header = Array.new
    header << "Date"
    if current then header << "Current" end
    if voltage then header << "Voltage" end
    if temperature then header << "Temperature" end
    csv << header
    @entries.each do |e|
      # if e.date_time <= DateTime.strptime(date2 << 'T'<< time2,'%Y-%m-%dT%H:%M:%S') && e.date_time >= DateTime.strptime(date1 << 'T'<< time1,'%Y-%m-%dT%H:%M:%S')
      # if e.date_time.getlocal >= date1 && e.date_time.getlocal <= date2
      if e.date_time >= dt1 && e.date_time <= dt2
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
  end 

  send_file 'public/data.csv', :disposition => "attachment"
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

get_or_post '/entries' do
  if session[:login]
    @title = "Entries"
    if !params[:numEntries]
      params[:numEntries] = 30
    end
    numEntr = 1
    @allEntries = Entry.all
    @entries = Array.new
    @allEntries.reverse.each do |entry|
      if numEntr > params[:numEntries].to_i
        break
      end
      numEntr = numEntr+1
      @entries << entry
    end
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
