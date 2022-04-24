require "bcrypt"
require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "redcarpet"
require "yaml"

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def users_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../admin/users.yml", __FILE__)
  end
end

def valid_signin?(username, password)
  credentials = YAML.load(File.read(users_path))[username]
  if credentials
    stored_password = BCrypt::Password.new(credentials)
    stored_password == password
  else
    false
  end
end

configure do
  enable :sessions
  set :session_secret, 'secret'
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  if File.extname(path) == ".md"
    render_markdown(content)
  else
    headers["Content-Type"] = "text/plain"
    content
  end
end

def signed_in?
  session.key?(:user)
end

def redirect_unless_signed_in
  return if signed_in?
  
  session[:message] = "You must be signed in to do that."
  redirect "/files"
end

get "/" do
  redirect "/files"
end

get "/files" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :filelist
end

get "/new" do
  erb :new
end

post "/files" do
  redirect_unless_signed_in
  
  filename = params[:new_file_name]
  if filename.empty?
    session[:message] = "Filename cannot be blank."
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)
    File.new(file_path, "w")
    session[:message] = "#{filename} was created."
    redirect "/files"
  end
end

def valid_file?(pathname)
  File.file? pathname
end

def file_does_not_exist_redirect(filename)
  session[:message] = "#{filename} does not exist."
  redirect "/files"
end

get "/:file" do
  file_path = File.join(data_path, params[:file])
  file_does_not_exist_redirect(params[:file]) unless valid_file? file_path
  
  load_file_content(file_path)
end

get "/:file/edit" do
  redirect_unless_signed_in
  
  @filename = params[:file]
  file_path = File.join(data_path, @filename)
  
  @content = load_file_content(file_path)
  headers["Content-Type"] = "text/html;charset=utf-8"
  erb :edit
end

post "/:file" do
  redirect_unless_signed_in
  
  filename = params[:file]
  file_path = File.join(data_path, filename)
  File.write(file_path, params[:content])
  session[:message] = "#{filename} has been updated."
  redirect "/files"
end

post "/:file/delete" do
  redirect_unless_signed_in
  
  filename = params[:file]
  file_path = File.join(data_path, filename)
  File.delete(file_path)
  session[:message] = "#{filename} was deleted."
  redirect "/files"
end

get "/users/signin" do
  erb :signin
end

post "/users/signin" do
  if valid_signin?(params[:username], params[:password])
    session[:message] = "Welcome!"
    session[:user] = params[:username]
    redirect "/files"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  session.delete(:user)
  session[:message] = "You have been signed out."
  redirect "/files"
end
