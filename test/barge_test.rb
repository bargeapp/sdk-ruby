require 'test_helper'

class BargeTest < MiniTest::Test
  def setup
    @client = Barge::Client.new api_key: '123456789'
    @base_url = "https://www.bargeapp.com"
    @success_body = '{"success": true}'
  end

  def test_throws_if_no_api_key
    assert_raises ArgumentError do
      @client = Barge::Client.new
    end
  end
  
  def test_create_webdriver_session_success
    stub_request(:post, "#{@base_url}/api/webdriver_sessions").to_return(status: 200, body: @success_body)
    resp = @client.create_webdriver_session(false)
    assert_equal JSON.parse(@success_body), resp
  end

  def test_create_webdriver_unauthorized
    stub_request(:post, "#{@base_url}/api/webdriver_sessions").to_return(status: 401)
    assert_raises Barge::UnauthorizedException do
      @client.create_webdriver_session(false)
    end
  end

  def test_describe_webdriver_sessions_success
    stub_request(:get, "#{@base_url}/api/webdriver_sessions/").to_return(status: 200, body: @success_body)
    resp = @client.describe_webdriver_sessions
    assert_equal JSON.parse(@success_body), resp
  end

  def test_describe_webdriver_sessions_not_found
    stub_request(:get, "#{@base_url}/api/webdriver_sessions/").to_return(status: 404)
    
    assert_raises Barge::NotFoundException do
      @client.describe_webdriver_sessions
    end
  end

  def test_create_webdriver_test_success
    stub_request(:post, "#{@base_url}/api/tests/create_webdriver").to_return(status: 201)
    resp = @client.create_webdriver_test
    assert_equal({}, resp)
  end
end