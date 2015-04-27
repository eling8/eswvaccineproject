require 'sinatra'
require 'twilio-ruby'
require 'sinatra/activerecord'
require './config/environments' #database configuration

# A hack around multiple routes in Sinatra
def get_or_post(path, opts={}, &block)
  get(path, opts, &block)
  post(path, opts, &block)
end

# Home page and reference
get '/' do
  @title = "Home"
  erb :home
end

# SMS Request URL
get_or_post '/sms/?' do
  sender = params[:From]
  body = params[:Body]
  
  @entry = Entry.new(:message => body, :sender => sender)
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
  @entries = Entry.all
  erb :entries
end