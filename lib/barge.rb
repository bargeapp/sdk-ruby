require "barge/version"
require 'net/http'
require 'json'

module Barge
  class BargeException < Exception ; end
  class UnauthorizedException < BargeException ; end
  class NotFoundException < BargeException ; end

  class Client
    def initialize(opts = {})
      @api_key      = opts[:api_key] or raise ArgumentError, 'api_key is required'
      @endpoint     = opts[:endpoint] || 'https://www.bargeapp.com/api'
      @ssl          = opts.has_key?(:ssl) ? !!opts[:ssl] : true
      @verify_mode  = opts[:verify_mode] || OpenSSL::SSL::VERIFY_PEER
    end

    def create_webdriver_session
      execute :post, 'webdriver_sessions'
    end

    def describe_webdriver_sessions(id = nil)
      execute :get, "webdriver_sessions/#{id}"
    end

    def create_webdriver_test(opts = {})
      execute :post, "tests/create_webdriver", {
        webdriver_session_id: opts[:webdriver_session_id],
        users: opts[:users],
        minutes: opts[:minutes]
      }
    end

    def describe_tests(id = nil)
      execute :get, "tests/#{id}"
    end

    private
    def execute(verb, path, params = {})
      klass_name = verb.slice(0,1).capitalize + verb.slice(1..-1).downcase
      klass = Net::HTTP.const_get(klass_name)

      uri = URI("#{@endpoint}/#{path}")
      http = Net::HTTP.new(uri.host, uri.port)

      if @ssl
        http.use_ssl = true
        http.verify_mode = @verify_mode
      end

      req = klass.new(uri.request_uri, initheader = { 'Content-Type' =>'application/json', 'API-KEY' => @api_key })


      if params.keys.count > 0
        req.body = params.to_json
      end

      res = http.request(req)

      case res.code
      when '200', '201', '422'
        if res.body && res.body.length > 2
          JSON.parse(res.body)
        else
          {}
        end
      when '401'
        # unauthorized
        raise UnauthorizedException
      when '404'
        # not found
        raise NotFoundException
      when '422'
        # bad params
        JSON.parse(res.body)
      else
        raise BargeException, "#{res.code}: #{res.body}"
      end
    end
  end
end
