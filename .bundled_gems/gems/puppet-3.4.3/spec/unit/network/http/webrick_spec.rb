#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/network/http'
require 'puppet/network/http/webrick'

describe Puppet::Network::HTTP::WEBrick, "after initializing" do
  it "should not be listening" do
    Puppet::Network::HTTP::WEBrick.new.should_not be_listening
  end
end

describe Puppet::Network::HTTP::WEBrick do
  include PuppetSpec::Files

  let(:address) { '127.0.0.1' }
  let(:port) { 31337 }

  let(:server) do
    s = Puppet::Network::HTTP::WEBrick.new
    s.stubs(:setup_logger).returns(Hash.new)
    s.stubs(:setup_ssl).returns(Hash.new)
    s
  end

  let(:mock_webrick) do
    stub('webrick',
         :[] => {},
         :listeners => [],
         :status => :Running,
         :mount => nil,
         :start => nil,
         :shutdown => nil)
  end

  before :each do
    WEBrick::HTTPServer.stubs(:new).returns(mock_webrick)
  end

  describe "when turning on listening" do
    it "should fail if already listening" do
      server.listen(address, port)
      expect { server.listen(address, port) }.to raise_error(RuntimeError, /server is already listening/)
    end

    it "should tell webrick to listen on the specified address and port" do
      WEBrick::HTTPServer.expects(:new).with(
        has_entries(:Port => 31337, :BindAddress => "127.0.0.1")
      ).returns(mock_webrick)
      server.listen(address, port)
    end

    it "should not perform reverse lookups" do
      WEBrick::HTTPServer.expects(:new).with(
        has_entry(:DoNotReverseLookup => true)
      ).returns(mock_webrick)
      BasicSocket.expects(:do_not_reverse_lookup=).with(true)

      server.listen(address, port)
    end

    it "should configure a logger for webrick" do
      server.expects(:setup_logger).returns(:Logger => :mylogger)

      WEBrick::HTTPServer.expects(:new).with {|args|
        args[:Logger] == :mylogger
      }.returns(mock_webrick)

      server.listen(address, port)
    end

    it "should configure SSL for webrick" do
      server.expects(:setup_ssl).returns(:Ssl => :testing, :Other => :yay)

      WEBrick::HTTPServer.expects(:new).with {|args|
        args[:Ssl] == :testing and args[:Other] == :yay
      }.returns(mock_webrick)

      server.listen(address, port)
    end

    it "should be listening" do
      server.listen(address, port)
      server.should be_listening
    end

    describe "when the REST protocol is requested" do
      it "should register the REST handler at /" do
        # We don't care about the options here.
        mock_webrick.expects(:mount).with("/", Puppet::Network::HTTP::WEBrickREST, anything)

        server.listen(address, port)
      end
    end
  end

  describe "when turning off listening" do
    it "should fail unless listening" do
      expect { server.unlisten }.to raise_error(RuntimeError, /server is not listening/)
    end

    it "should order webrick server to stop" do
      mock_webrick.expects(:shutdown)
      server.listen(address, port)
      server.unlisten
    end

    it "should no longer be listening" do
      server.listen(address, port)
      server.unlisten
      server.should_not be_listening
    end
  end

  describe "when configuring an http logger" do
    let(:server) { Puppet::Network::HTTP::WEBrick.new }

    before :each do
      Puppet.settings.stubs(:use)
      @filehandle = stub 'handle', :fcntl => nil, :sync= => nil

      File.stubs(:open).returns @filehandle
    end

    it "should use the settings for :main, :ssl, and :application" do
      Puppet.settings.expects(:use).with(:main, :ssl, :application)

      server.setup_logger
    end

    it "should use the masterlog if the run_mode is master" do
      Puppet.run_mode.stubs(:master?).returns(true)
      log = make_absolute("/master/log")
      Puppet[:masterhttplog] = log

      File.expects(:open).with(log, "a+").returns @filehandle

      server.setup_logger
    end

    it "should use the httplog if the run_mode is not master" do
      Puppet.run_mode.stubs(:master?).returns(false)
      log = make_absolute("/other/log")
      Puppet[:httplog] = log

      File.expects(:open).with(log, "a+").returns @filehandle

      server.setup_logger
    end

    describe "and creating the logging filehandle" do
      it "should set the close-on-exec flag if supported" do
        if defined? Fcntl::FD_CLOEXEC
          @filehandle.expects(:fcntl).with(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
        else
          @filehandle.expects(:fcntl).never
        end

        server.setup_logger
      end

      it "should sync the filehandle" do
        @filehandle.expects(:sync=).with(true)

        server.setup_logger
      end
    end

    it "should create a new WEBrick::Log instance with the open filehandle" do
      WEBrick::Log.expects(:new).with(@filehandle)

      server.setup_logger
    end

    it "should set debugging if the current loglevel is :debug" do
      Puppet::Util::Log.expects(:level).returns :debug

      WEBrick::Log.expects(:new).with { |handle, debug| debug == WEBrick::Log::DEBUG }

      server.setup_logger
    end

    it "should return the logger as the main log" do
      logger = mock 'logger'
      WEBrick::Log.expects(:new).returns logger

      server.setup_logger[:Logger].should == logger
    end

    it "should return the logger as the access log using both the Common and Referer log format" do
      logger = mock 'logger'
      WEBrick::Log.expects(:new).returns logger

      server.setup_logger[:AccessLog].should == [
        [logger, WEBrick::AccessLog::COMMON_LOG_FORMAT],
        [logger, WEBrick::AccessLog::REFERER_LOG_FORMAT]
      ]
    end
  end

  describe "when configuring ssl" do
    let(:server) { Puppet::Network::HTTP::WEBrick.new }
    let(:localcacert) { make_absolute("/ca/crt") }
    let(:ssl_server_ca_auth) { make_absolute("/ca/ssl_server_auth_file") }
    let(:key) { stub 'key', :content => "mykey" }
    let(:cert) { stub 'cert', :content => "mycert" }
    let(:host) { stub 'host', :key => key, :certificate => cert, :name => "yay", :ssl_store => "mystore" }

    before :each do
      Puppet::SSL::Certificate.indirection.stubs(:find).with('ca').returns cert
      Puppet::SSL::Host.stubs(:localhost).returns host
    end

    it "should use the key from the localhost SSL::Host instance" do
      Puppet::SSL::Host.expects(:localhost).returns host
      host.expects(:key).returns key

      server.setup_ssl[:SSLPrivateKey].should == "mykey"
    end

    it "should configure the certificate" do
      server.setup_ssl[:SSLCertificate].should == "mycert"
    end

    it "should fail if no CA certificate can be found" do
      Puppet::SSL::Certificate.indirection.stubs(:find).with('ca').returns nil

      expect { server.setup_ssl }.to raise_error(Puppet::Error, /Could not find CA certificate/)
    end

    it "should specify the path to the CA certificate" do
      Puppet.settings[:hostcrl] = 'false'
      Puppet.settings[:localcacert] = localcacert

      server.setup_ssl[:SSLCACertificateFile].should == localcacert
    end

    it "should specify the path to the CA certificate" do
      Puppet.settings[:hostcrl] = 'false'
      Puppet.settings[:localcacert] = localcacert
      Puppet.settings[:ssl_server_ca_auth] = ssl_server_ca_auth

      server.setup_ssl[:SSLCACertificateFile].should == ssl_server_ca_auth
    end

    it "should start ssl immediately" do
      server.setup_ssl[:SSLStartImmediately].should be_true
    end

    it "should enable ssl" do
      server.setup_ssl[:SSLEnable].should be_true
    end

    it "should reject SSLv2" do
      server.setup_ssl[:SSLOptions].should == OpenSSL::SSL::OP_NO_SSLv2
    end

    it "should configure the verification method as 'OpenSSL::SSL::VERIFY_PEER'" do
      server.setup_ssl[:SSLVerifyClient].should == OpenSSL::SSL::VERIFY_PEER
    end

    it "should add an x509 store" do
      host.expects(:ssl_store).returns "mystore"

      server.setup_ssl[:SSLCertificateStore].should == "mystore"
    end

    it "should set the certificate name to 'nil'" do
      server.setup_ssl[:SSLCertName].should be_nil
    end
  end
end
