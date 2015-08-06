# encoding: utf-8
require 'spec_helper'
require 'net/http'
require 'puppet/forge/repository'
require 'puppet/forge/cache'
require 'puppet/forge/errors'

describe Puppet::Forge::Repository do
  let(:consumer_version) { "Test/1.0" }
  let(:repository) { Puppet::Forge::Repository.new('http://fake.com', consumer_version) }
  let(:ssl_repository) { Puppet::Forge::Repository.new('https://fake.com', consumer_version) }

  it "retrieve accesses the cache" do
    path = '/module/foo.tar.gz'
    repository.cache.expects(:retrieve)

    repository.retrieve(path)
  end

  it "retrieve merges forge URI and path specified" do
    path = '/module/foo.tar.gz'
    repo_uri = 'http://fake.com/test'
    repository = Puppet::Forge::Repository.new(repo_uri, consumer_version)
    repository.cache.expects(:retrieve).with(URI.parse(repo_uri+path))

    repository.retrieve(path)
  end

  describe "making a request" do
    before :each do
      proxy_settings_of("proxy", 1234)
    end

    it "returns the result object from the request" do
      result = "the http response"
      performs_an_http_request result do |http|
        http.expects(:request).with(responds_with(:path, "the_path"))
      end

      repository.make_http_request("the_path").should == result
    end

    it 'returns the result object from a request with ssl' do
      result = "the http response"
      performs_an_https_request result do |http|
        http.expects(:request).with(responds_with(:path, "the_path"))
      end

      ssl_repository.make_http_request("the_path").should == result
    end

    it 'return a valid exception when there is an SSL verification problem' do
      performs_an_https_request "the http response" do |http|
        http.expects(:request).with(responds_with(:path, "the_path")).raises OpenSSL::SSL::SSLError.new("certificate verify failed")
      end

      expect { ssl_repository.make_http_request("the_path") }.to raise_error Puppet::Forge::Errors::SSLVerifyError, 'Unable to verify the SSL certificate at https://fake.com'
    end

    it 'return a valid exception when there is a communication problem' do
      performs_an_http_request "the http response" do |http|
        http.expects(:request).with(responds_with(:path, "the_path")).raises SocketError
      end

      expect { repository.make_http_request("the_path") }.
        to raise_error Puppet::Forge::Errors::CommunicationError,
        'Unable to connect to the server at http://fake.com. Detail: SocketError.'
    end

    it "sets the user agent for the request" do
      performs_an_http_request do |http|
        http.expects(:request).with() do |request|
          puppet_version = /Puppet\/\d+\..*/
          os_info = /\(.*\)/
          ruby_version = /Ruby\/\d+\.\d+\.\d+(-p-?\d+)? \(\d{4}-\d{2}-\d{2}; .*\)/

          request["User-Agent"] =~ /^#{consumer_version} #{puppet_version} #{os_info} #{ruby_version}/
        end
      end

      repository.make_http_request("the_path")
    end

    it "escapes the received URI" do
      unescaped_uri = "héllo world !! ç à"
      performs_an_http_request do |http|
        http.expects(:request).with(responds_with(:path, URI.escape(unescaped_uri)))
      end

      repository.make_http_request(unescaped_uri)
    end

    def performs_an_http_request(result = nil, &block)
      http = mock("http client")
      yield http

      proxy_class = mock("http proxy class")
      proxy = mock("http proxy")
      proxy_class.expects(:new).with("fake.com", 80).returns(proxy)
      proxy.expects(:start).yields(http).returns(result)
      Net::HTTP.expects(:Proxy).with("proxy", 1234).returns(proxy_class)
    end

    def performs_an_https_request(result = nil, &block)
      http = mock("http client")
      yield http

      proxy_class = mock("http proxy class")
      proxy = mock("http proxy")
      proxy_class.expects(:new).with("fake.com", 443).returns(proxy)
      proxy.expects(:start).yields(http).returns(result)
      proxy.expects(:use_ssl=).with(true)
      proxy.expects(:cert_store=)
      proxy.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
      Net::HTTP.expects(:Proxy).with("proxy", 1234).returns(proxy_class)
    end
  end

  def proxy_settings_of(host, port)
    Puppet[:http_proxy_host] = host
    Puppet[:http_proxy_port] = port
  end
end
