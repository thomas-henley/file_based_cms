require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "redcarpet"

root = File.expand_path("..", __FILE__)

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
    

get "/" do
  redirect "/files"
end

get "/files" do
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  erb :filelist
end

def valid_file?(pathname)
  File.file? pathname
end

def file_does_not_exist_redirect(filename)
  session[:error] = "#{filename} does not exist."
  redirect "/files"
end

get "/:file" do
  file_path = root + "/data/" + params[:file]
  file_does_not_exist_redirect(params[:file]) unless valid_file? file_path
  
  load_file_content(file_path)
end
