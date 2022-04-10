ENV["RACK_ENV"] = "test"

require "fileutils"
require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods
  
  def setup
    FileUtils.mkdir_p(data_path)
  end
  
  def teardown
    FileUtils.rm_rf(data_path)
  end
  
  def app
    Sinatra::Application
  end
  
  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end
  
  def test_get_root
    create_document("about.md")
    create_document("changes.txt")
    
    get "/"
    
    assert_equal 302, last_response.status
    assert_equal "files", last_response["location"].split("/").last
    follow_redirect!
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes(last_response.body, ">Edit</a>")
  end
  
  def test_get_files
    create_document("about.md")
    create_document("changes.txt")
    
    get "/files"
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes(last_response.body, ">Edit</a>")
    assert_includes(last_response.body, "type=\"submit\" value=\"Delete\"")
    assert_includes(last_response.body, ">New Document</a>")
  end
  
  def test_get_a_file
    create_document("about.txt", "ABOUT")
    
    get "/about.txt"
    
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["content-type"]
    assert_equal "ABOUT", last_response.body[0,5]
  end
  
  def test_edit_file
    create_document("history.txt")
    
    get "/history.txt/edit"
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes(last_response.body, "Edit content of history.txt:")
    assert_includes(last_response.body, "<textarea")
    assert_includes(last_response.body, "<input type=\"submit")
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
    create_document("about.md", "#ABOUT")
    
    get "/about.md"
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes(last_response.body, "<h1>ABOUT</h1>")
  end

  def test_updating_document
    post "/history.txt", content: "new content"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes(last_response.body, "history.txt has been updated")

    get "/history.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end
  
  def test_get_new_document
    get "/new"
    
    assert_equal 200, last_response.status
    
    assert_includes last_response.body, "Add a new document:"
    assert_includes last_response.body, "input type="
  end
  
  def test_create_new_document
    post "/files", new_file_name: "new_file_test.txt"
    
    assert_equal 302, last_response.status
    
    get last_response["Location"]
    
    assert_includes last_response.body, "new_file_test.txt was created."
    assert_includes last_response.body, ">new_file_test.txt</a>"
  end
  
  def test_create_new_document_with_invalid_name
    post "/files", new_file_name: ""
    
    assert_equal 422, last_response.status
    
    assert_includes last_response.body, "Filename cannot be blank."
    assert_includes last_response.body, "Add a new document:"
    assert_includes last_response.body, "input type="
  end
  
  def test_delete_file
    create_document("delete_me.txt", "kill me!")
    create_document("leave_me.txt", "let me live!")
    
    post "/delete_me.txt/delete"
    
    assert_equal 302, last_response.status
    
    get last_response["Location"]
    
    assert_includes last_response.body, "delete_me.txt was deleted."
    assert_includes last_response.body, "leave_me.txt</a>"
    refute_includes last_response.body, "delete_me.txt</a>"
  end
  
  def test_root_shows_sign_in_button
    get "/files"
    
    assert_equal 200, last_response.status
    
    assert_includes last_response.body, "action=\"/users/signin\""
    assert_includes last_response.body, "value=\"Sign In\""
  end
  
  def test_get_sign_in
    get "/users/signin"
    
    assert_equal 200, last_response.status
    
    assert_includes last_response.body, "Username:"
    assert_includes last_response.body, "Password:"
    assert_includes last_response.body, "action=\"/users/signin\" method=\"post\""
  end
end