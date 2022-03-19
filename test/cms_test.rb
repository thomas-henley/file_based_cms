ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  def test_get_root
    get "/"
    
    assert_equal 302, last_response.status
    assert_equal "files", last_response["location"].split("/").last
    follow_redirect!
    assert_equal 200, last_response.status
  end
  
  def test_get_files
    get "/files"
    
    assert_equal 200, last_response.status
  end
  
  def test_get_a_file
    get "/history.txt"
    
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["content-type"]
    assert_equal "HISTORY", last_response.body[0,7]
  end
  
  def test_file_does_not_exist
    get "/no_file.txt"
    
    assert_equal 302, last_response.status
    assert_equal "files", last_response["location"].split("/").last
    
    follow_redirect!
    
    assert_equal 200, last_response.status
    assert_includes(last_response.body, "no_file.txt does not exist.")
    
    get "/files"
    refute_includes(last_response.body, "no_file.txt does not exist.")
  end
  
  def test_viewing_markdown_document
    get "/mark.md"
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes(last_response.body, "<h1>This is big!</h1>")
  end
end