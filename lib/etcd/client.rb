require 'net/http'
require 'json'
require 'hashie'
require 'etcd/log'

module Etcd
  class Client

    attr_reader :host, :port, :http, :allow_redirect

    def initialize(opts={})
      @host = opts[:host] || '127.0.0.1'
      @port = opts[:port] || 4001
      @allow_redirect = opts[:allow_redirect] || true
    end

    def version_prefix
      '/v1'
    end

    def machines
      api_execute('/machines', :get).split(",")
    end

    def leader
      api_execute('/leader', :get)
    end

    def key_endpoint
      version_prefix + '/keys'
    end

    def watch_endpoint
      version_prefix + '/watch'
    end

    def test_and_set(key, value, prevValue, ttl = nil)
      path  = key_endpoint + key
      payload = {'value' => value, 'prevValue' => prevValue }
      payload['ttl'] = ttl unless ttl.nil?
      response = api_execute(path, :post, payload)
      Hashie::Mash.new(JSON.parse(response))
    end

    def set(key, value, ttl=nil)
      path  = key_endpoint + key
      payload = {'value' => value} 
      payload['ttl'] = ttl unless ttl.nil?
      response = api_execute(path, :post, payload)
      Hashie::Mash.new(JSON.parse(response))
    end

    def delete(key)
      response = api_execute(key_endpoint + key, :delete)
      Hashie::Mash.new(JSON.parse(response))
    end

    def get(key)
      response = api_execute(key_endpoint + key, :get)
      obj = JSON.parse(response)
      if obj.is_a?(Array)
        obj.map{|e| Hashie::Mash.new(e)}
      else
        Hashie::Mash.new(obj)
      end
    end

    def watch(key, index=nil)
      response = if index.nil?
                    api_execute(watch_endpoint + key, :get)
                  else
                    api_execute(watch_endpoint + key, :post, {'index' => index})
                  end
      Hashie::Mash.new(JSON.parse(response))
    end

    def api_execute(path, method, params=nil)

      http = if path=~/^http/
                uri = URI.parse(path)
                path =  uri.path
                Net::HTTP.new(uri.host, uri.port)
              else
                Net::HTTP.new(host, port)
              end

      case  method
      when :get 
        unless params.nil?
          encoded_params = URI.encode_www_form(params)
          path+= "?" + encoded_params
        end
        req = Net::HTTP::Get.new(path)
      when :post
        encoded_params = URI.encode_www_form(params)
        req = Net::HTTP::Post.new(path)
        req.body= encoded_params
        Log.debug("Setting body for post '#{encoded_params}'")
      when :delete
        unless params.nil?
          encoded_params = URI.encode_www_form(params)
          path+= "?" + encoded_params
        end
        req = Net::HTTP::Delete.new(path)
      end

      Log.debug("Invoking: '#{req.class}' against '#{path}")
      res = http.request(req)
      Log.debug("Response code: #{res.code}")
      if res.is_a?(Net::HTTPSuccess) 
        Log.debug("Http success")
        res.body
      elsif redirect?(res.code.to_i) and allow_redirect
        Log.debug("Http redirect, following")
        api_execute(res['location'], method, params)
      else
        Log.debug("Http error")
        Log.debug(res.body)
        #res.error!
        res
      end
    end

    def redirect?(code)
      (code >= 300) and (code < 400)
    end
  end
end
