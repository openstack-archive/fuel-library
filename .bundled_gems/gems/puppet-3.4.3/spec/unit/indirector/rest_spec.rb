#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/indirector'
require 'puppet/indirector/errors'
require 'puppet/indirector/rest'

HTTP_ERROR_CODES = [300, 400, 500]

# Just one from each category since the code makes no real distinctions
shared_examples_for "a REST terminus method" do |terminus_method|
  describe "when talking to an older master" do
    it "should set backward compatibility settings" do
      response.stubs(:[]).with(Puppet::Network::HTTP::HEADER_PUPPET_VERSION).returns nil

      terminus.send(terminus_method, request)
      Puppet[:report_serialization_format].should == 'yaml'
      Puppet[:legacy_query_parameter_serialization].should == true
    end
  end

  describe "when talking to a 3.3.1 master" do
    it "should not set backward compatibility settings" do
      response.stubs(:[]).with(Puppet::Network::HTTP::HEADER_PUPPET_VERSION).returns "3.3.1"

      terminus.send(terminus_method, request)
      Puppet[:report_serialization_format].should == 'pson'
      Puppet[:legacy_query_parameter_serialization].should == false
    end
  end

  HTTP_ERROR_CODES.each do |code|
    describe "when the response code is #{code}" do
      let(:response) { mock_response(code, 'error messaged!!!') }

      it "raises an http error with the body of the response" do
        expect {
          terminus.send(terminus_method, request)
        }.to raise_error(Net::HTTPError, "Error #{code} on SERVER: #{response.body}")
      end

      it "does not attempt to deserialize the response" do
        model.expects(:convert_from).never

        expect {
          terminus.send(terminus_method, request)
        }.to raise_error(Net::HTTPError)
      end

      # I'm not sure what this means or if it's used
      it "if the body is empty raises an http error with the response header" do
        response.stubs(:body).returns ""
        response.stubs(:message).returns "fhqwhgads"

        expect {
          terminus.send(terminus_method, request)
        }.to raise_error(Net::HTTPError, "Error #{code} on SERVER: #{response.message}")
      end

      describe "and the body is compressed" do
        it "raises an http error with the decompressed body of the response" do
          uncompressed_body = "why"
          compressed_body = Zlib::Deflate.deflate(uncompressed_body)

          response = mock_response(code, compressed_body, 'text/plain', 'deflate')
          connection.expects(http_method).returns(response)

          expect {
            terminus.send(terminus_method, request)
          }.to raise_error(Net::HTTPError, "Error #{code} on SERVER: #{uncompressed_body}")
        end
      end
    end
  end
end

shared_examples_for "a deserializing terminus method" do |terminus_method|
  describe "when the response has no content-type" do
    let(:response) { mock_response(200, "body", nil, nil) }
    it "raises an error" do
      expect {
        terminus.send(terminus_method, request)
      }.to raise_error(RuntimeError, "No content type in http response; cannot parse")
    end
  end

  it "doesn't catch errors in deserialization" do
    model.expects(:convert_from).raises(Puppet::Error, "Whoa there")

    expect { terminus.send(terminus_method, request) }.to raise_error(Puppet::Error, "Whoa there")
  end
end

describe Puppet::Indirector::REST do
  before :all do
    class Puppet::TestModel
      extend Puppet::Indirector
      indirects :test_model
      attr_accessor :name, :data
      def initialize(name = "name", data = '')
        @name = name
        @data = data
      end

      def self.convert_from(format, string)
        new('', string)
      end

      def self.convert_from_multiple(format, string)
        string.split(',').collect { |s| convert_from(format, s) }
      end

      def to_data_hash
        { 'name' => @name, 'data' => @data }
      end

      def ==(other)
        other.is_a? Puppet::TestModel and other.name == name and other.data == data
      end
    end

    # The subclass must not be all caps even though the superclass is
    class Puppet::TestModel::Rest < Puppet::Indirector::REST
    end

    Puppet::TestModel.indirection.terminus_class = :rest
  end

  after :all do
    Puppet::TestModel.indirection.delete
    # Remove the class, unlinking it from the rest of the system.
    Puppet.send(:remove_const, :TestModel)
  end

  let(:terminus_class) { Puppet::TestModel::Rest }
  let(:terminus) { Puppet::TestModel.indirection.terminus(:rest) }
  let(:indirection) { Puppet::TestModel.indirection }
  let(:model) { Puppet::TestModel }

  def mock_response(code, body, content_type='text/plain', encoding=nil)
    obj = stub('http 200 ok', :code => code.to_s, :body => body)
    obj.stubs(:[]).with('content-type').returns(content_type)
    obj.stubs(:[]).with('content-encoding').returns(encoding)
    obj.stubs(:[]).with(Puppet::Network::HTTP::HEADER_PUPPET_VERSION).returns(Puppet.version)
    obj
  end

  def find_request(key, options={})
    Puppet::Indirector::Request.new(:test_model, :find, key, nil, options)
  end

  def head_request(key, options={})
    Puppet::Indirector::Request.new(:test_model, :head, key, nil, options)
  end

  def search_request(key, options={})
    Puppet::Indirector::Request.new(:test_model, :search, key, nil, options)
  end

  def delete_request(key, options={})
    Puppet::Indirector::Request.new(:test_model, :destroy, key, nil, options)
  end

  def save_request(key, instance, options={})
    Puppet::Indirector::Request.new(:test_model, :save, key, instance, options)
  end

  it "should include the v1 REST API module" do
    Puppet::Indirector::REST.ancestors.should be_include(Puppet::Network::HTTP::API::V1)
  end

  it "should have a method for specifying what setting a subclass should use to retrieve its server" do
    terminus_class.should respond_to(:use_server_setting)
  end

  it "should use any specified setting to pick the server" do
    terminus_class.expects(:server_setting).returns :inventory_server
    Puppet[:inventory_server] = "myserver"
    terminus_class.server.should == "myserver"
  end

  it "should default to :server for the server setting" do
    terminus_class.expects(:server_setting).returns nil
    Puppet[:server] = "myserver"
    terminus_class.server.should == "myserver"
  end

  it "should have a method for specifying what setting a subclass should use to retrieve its port" do
    terminus_class.should respond_to(:use_port_setting)
  end

  it "should use any specified setting to pick the port" do
    terminus_class.expects(:port_setting).returns :ca_port
    Puppet[:ca_port] = "321"
    terminus_class.port.should == 321
  end

  it "should default to :port for the port setting" do
    terminus_class.expects(:port_setting).returns nil
    Puppet[:masterport] = "543"
    terminus_class.port.should == 543
  end

  it 'should default to :puppet for the srv_service' do
    Puppet::Indirector::REST.srv_service.should == :puppet
  end

  describe "when creating an HTTP client" do
    it "should use the class's server and port if the indirection request provides neither" do
      @request = stub 'request', :key => "foo", :server => nil, :port => nil
      terminus.class.expects(:port).returns 321
      terminus.class.expects(:server).returns "myserver"
      Puppet::Network::HttpPool.expects(:http_instance).with("myserver", 321).returns "myconn"
      terminus.network(@request).should == "myconn"
    end

    it "should use the server from the indirection request if one is present" do
      @request = stub 'request', :key => "foo", :server => "myserver", :port => nil
      terminus.class.stubs(:port).returns 321
      Puppet::Network::HttpPool.expects(:http_instance).with("myserver", 321).returns "myconn"
      terminus.network(@request).should == "myconn"
    end

    it "should use the port from the indirection request if one is present" do
      @request = stub 'request', :key => "foo", :server => nil, :port => 321
      terminus.class.stubs(:server).returns "myserver"
      Puppet::Network::HttpPool.expects(:http_instance).with("myserver", 321).returns "myconn"
      terminus.network(@request).should == "myconn"
    end
  end

  describe "#find" do
    let(:http_method) { :get }
    let(:response) { mock_response(200, 'body') }
    let(:connection) { stub('mock http connection', :get => response, :verify_callback= => nil) }
    let(:request) { find_request('foo') }

    before :each do
      terminus.stubs(:network).returns(connection)
    end

    it_behaves_like 'a REST terminus method', :find
    it_behaves_like 'a deserializing terminus method', :find

    describe "with a long set of parameters" do
      it "calls post on the connection with the query params in the body" do
        params = {}
        'aa'.upto('zz') do |s|
          params[s] = 'foo'
        end

        # The request special-cases this parameter, and it
        # won't be passed on to the server, so we remove it here
        # to avoid a failure.
        params.delete('ip')

        request = find_request('whoa', params)

        connection.expects(:post).with do |uri, body|
          body.split("&").sort == params.map {|key,value| "#{key}=#{value}"}.sort
        end.returns(mock_response(200, 'body'))

        terminus.find(request)
      end
    end

    describe "with no parameters" do
      it "calls get on the connection" do
        request = find_request('foo bar')

        connection.expects(:get).with('/production/test_model/foo%20bar?', anything).returns(mock_response('200', 'response body'))

        terminus.find(request).should == model.new('foo bar', 'response body')
      end
    end

    it "returns nil on 404" do
      response = mock_response('404', nil)

      connection.expects(:get).returns(response)

      terminus.find(request).should == nil
    end

    it "asks the model to deserialize the response body and sets the name on the resulting object to the find key" do
      connection.expects(:get).returns response

      model.expects(:convert_from).with(response['content-type'], response.body).returns(
        model.new('overwritten', 'decoded body')
      )

      terminus.find(request).should == model.new('foo', 'decoded body')
    end

    it "doesn't require the model to support name=" do
      connection.expects(:get).returns response
      instance = model.new('name', 'decoded body')

      model.expects(:convert_from).with(response['content-type'], response.body).returns(instance)
      instance.expects(:respond_to?).with(:name=).returns(false)
      instance.expects(:name=).never

      terminus.find(request).should == model.new('name', 'decoded body')
    end

    it "provides an Accept header containing the list of supported formats joined with commas" do
      connection.expects(:get).with(anything, has_entry("Accept" => "supported, formats")).returns(response)

      terminus.model.expects(:supported_formats).returns %w{supported formats}
      terminus.find(request)
    end

    it "adds an Accept-Encoding header" do
      terminus.expects(:add_accept_encoding).returns({"accept-encoding" => "gzip"})

      connection.expects(:get).with(anything, has_entry("accept-encoding" => "gzip")).returns(response)

      terminus.find(request)
    end

    it "uses only the mime-type from the content-type header when asking the model to deserialize" do
      response = mock_response('200', 'mydata', "text/plain; charset=utf-8")
      connection.expects(:get).returns(response)

      model.expects(:convert_from).with("text/plain", "mydata").returns "myobject"

      terminus.find(request).should == "myobject"
    end

    it "decompresses the body before passing it to the model for deserialization" do
      uncompressed_body = "Why hello there"
      compressed_body = Zlib::Deflate.deflate(uncompressed_body)

      response = mock_response('200', compressed_body, 'text/plain', 'deflate')
      connection.expects(:get).returns(response)

      model.expects(:convert_from).with("text/plain", uncompressed_body).returns "myobject"

      terminus.find(request).should == "myobject"
    end
  end

  describe "#head" do
    let(:http_method) { :head }
    let(:response) { mock_response(200, nil) }
    let(:connection) { stub('mock http connection', :head => response, :verify_callback= => nil) }
    let(:request) { head_request('foo') }

    before :each do
      terminus.stubs(:network).returns(connection)
    end

    it_behaves_like 'a REST terminus method', :head

    it "returns true if there was a successful http response" do
      connection.expects(:head).returns mock_response('200', nil)

      terminus.head(request).should == true
    end

    it "returns false on a 404 response" do
      connection.expects(:head).returns mock_response('404', nil)

      terminus.head(request).should == false
    end
  end

  describe "#search" do
    let(:http_method) { :get }
    let(:response) { mock_response(200, 'data1,data2,data3') }
    let(:connection) { stub('mock http connection', :get => response, :verify_callback= => nil) }
    let(:request) { search_request('foo') }

    before :each do
      terminus.stubs(:network).returns(connection)
    end

    it_behaves_like 'a REST terminus method', :search
    it_behaves_like 'a deserializing terminus method', :search

    it "should call the GET http method on a network connection" do
      connection.expects(:get).with('/production/test_models/foo', has_key('Accept')).returns mock_response(200, 'data3, data4')

      terminus.search(request)
    end

    it "returns an empty list on 404" do
      response = mock_response('404', nil)

      connection.expects(:get).returns(response)

      terminus.search(request).should == []
    end

    it "asks the model to deserialize the response body into multiple instances" do
      terminus.search(request).should == [model.new('', 'data1'), model.new('', 'data2'), model.new('', 'data3')]
    end

    it "should provide an Accept header containing the list of supported formats joined with commas" do
      connection.expects(:get).with(anything, has_entry("Accept" => "supported, formats")).returns(mock_response(200, ''))

      terminus.model.expects(:supported_formats).returns %w{supported formats}
      terminus.search(request)
    end

    it "should return an empty array if serialization returns nil" do
      model.stubs(:convert_from_multiple).returns nil

      terminus.search(request).should == []
    end
  end

  describe "#destroy" do
    let(:http_method) { :delete }
    let(:response) { mock_response(200, 'body') }
    let(:connection) { stub('mock http connection', :delete => response, :verify_callback= => nil) }
    let(:request) { delete_request('foo') }

    before :each do
      terminus.stubs(:network).returns(connection)
    end

    it_behaves_like 'a REST terminus method', :destroy
    it_behaves_like 'a deserializing terminus method', :destroy

    it "should call the DELETE http method on a network connection" do
      connection.expects(:delete).with('/production/test_model/foo', has_key('Accept')).returns(response)

      terminus.destroy(request)
    end

    it "should fail if any options are provided, since DELETE apparently does not support query options" do
      request = delete_request('foo', :one => "two", :three => "four")

      expect { terminus.destroy(request) }.to raise_error(ArgumentError)
    end

    it "should deserialize and return the http response" do
      connection.expects(:delete).returns response

      terminus.destroy(request).should == model.new('', 'body')
    end

    it "returns nil on 404" do
      response = mock_response('404', nil)

      connection.expects(:delete).returns(response)

      terminus.destroy(request).should == nil
    end

    it "should provide an Accept header containing the list of supported formats joined with commas" do
      connection.expects(:delete).with(anything, has_entry("Accept" => "supported, formats")).returns(response)

      terminus.model.expects(:supported_formats).returns %w{supported formats}
      terminus.destroy(request)
    end
  end

  describe "#save" do
    let(:http_method) { :put }
    let(:response) { mock_response(200, 'body') }
    let(:connection) { stub('mock http connection', :put => response, :verify_callback= => nil) }
    let(:instance) { model.new('the thing', 'some contents') }
    let(:request) { save_request(instance.name, instance) }

    before :each do
      terminus.stubs(:network).returns(connection)
    end

    it_behaves_like 'a REST terminus method', :save

    it "should call the PUT http method on a network connection" do
      connection.expects(:put).with('/production/test_model/the%20thing', anything, has_key("Content-Type")).returns response

      terminus.save(request)
    end

    it "should fail if any options are provided, since PUT apparently does not support query options" do
      request = save_request(instance.name, instance, :one => "two", :three => "four")

      expect { terminus.save(request) }.to raise_error(ArgumentError)
    end

    it "should serialize the instance using the default format and pass the result as the body of the request" do
      instance.expects(:render).returns "serial_instance"
      connection.expects(:put).with(anything, "serial_instance", anything).returns response

      terminus.save(request)
    end

    it "returns nil on 404" do
      response = mock_response('404', nil)

      connection.expects(:put).returns(response)

      terminus.save(request).should == nil
    end

    it "returns nil" do
      connection.expects(:put).returns response

      terminus.save(request).should be_nil
    end

    it "should provide an Accept header containing the list of supported formats joined with commas" do
      connection.expects(:put).with(anything, anything, has_entry("Accept" => "supported, formats")).returns(response)

      instance.expects(:render).returns('')
      model.expects(:supported_formats).returns %w{supported formats}
      instance.expects(:mime).returns "supported"

      terminus.save(request)
    end

    it "should provide a Content-Type header containing the mime-type of the sent object" do
      instance.expects(:mime).returns "mime"
      connection.expects(:put).with(anything, anything, has_entry('Content-Type' => "mime")).returns(response)

      terminus.save(request)
    end
  end

  context 'dealing with SRV settings' do
    [
      :destroy,
      :find,
      :head,
      :save,
      :search
    ].each do |method|
      it "##{method} passes the SRV service, and fall-back server & port to the request's do_request method" do
        request = Puppet::Indirector::Request.new(:indirection, method, 'key', nil)
        stub_response = mock_response('200', 'body')

        request.expects(:do_request).with(terminus.class.srv_service, terminus.class.server, terminus.class.port).returns(stub_response)

        terminus.send(method, request)
      end
    end
  end
end
