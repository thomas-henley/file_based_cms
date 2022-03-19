require "sinatra"
require "sinatra/reloader" if development?
require "erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

get "/" do
  redirect "/files"
end

get "/files" do
  @files = Dir.children("data")
  erb :filelist
end

def valid_file?(filename)
  Dir.children("data").include?(filename)
end

def file_does_not_exist_redirect(filename)
  session[:error] = "#{filename} does not exist."
  redirect "/files"
end

get "/:file" do
  file_does_not_exist_redirect(params[:file]) unless valid_file? params[:file]
  
  relative_file_path = "./data/" + params[:file]
  
  headers["Content-Type"] = "text/plain"
  File.read(relative_file_path)
end
