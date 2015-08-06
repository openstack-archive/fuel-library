#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/indirector/key/file'

describe Puppet::SSL::Key::File do
  it "should have documentation" do
    Puppet::SSL::Key::File.doc.should be_instance_of(String)
  end

  it "should use the :privatekeydir as the collection directory" do
    Puppet[:privatekeydir] = File.expand_path("/key/dir")
    Puppet::SSL::Key::File.collection_directory.should == Puppet[:privatekeydir]
  end

  it "should store the ca key at the :cakey location" do
    Puppet.settings.stubs(:use)
    Puppet[:cakey] = File.expand_path("/ca/key")
    file = Puppet::SSL::Key::File.new
    file.stubs(:ca?).returns true
    file.path("whatever").should == Puppet[:cakey]
  end

  describe "when choosing the path for the public key" do
    it "should use the :capub setting location if the key is for the certificate authority" do
      Puppet[:capub] = File.expand_path("/ca/pubkey")
      Puppet.settings.stubs(:use)

      @searcher = Puppet::SSL::Key::File.new
      @searcher.stubs(:ca?).returns true
      @searcher.public_key_path("whatever").should == Puppet[:capub]
    end

    it "should use the host name plus '.pem' in :publickeydir for normal hosts" do
      Puppet[:privatekeydir] = File.expand_path("/private/key/dir")
      Puppet[:publickeydir] = File.expand_path("/public/key/dir")
      Puppet.settings.stubs(:use)

      @searcher = Puppet::SSL::Key::File.new
      @searcher.stubs(:ca?).returns false
      @searcher.public_key_path("whatever").should == File.expand_path("/public/key/dir/whatever.pem")
    end
  end

  describe "when managing private keys" do
    before do
      @searcher = Puppet::SSL::Key::File.new

      @private_key_path = File.join("/fake/key/path")
      @public_key_path = File.join("/other/fake/key/path")

      @searcher.stubs(:public_key_path).returns @public_key_path
      @searcher.stubs(:path).returns @private_key_path

      FileTest.stubs(:directory?).returns true
      FileTest.stubs(:writable?).returns true

      @public_key = stub 'public_key'
      @real_key = stub 'sslkey', :public_key => @public_key

      @key = stub 'key', :name => "myname", :content => @real_key

      @request = stub 'request', :key => "myname", :instance => @key
    end

    it "should save the public key when saving the private key" do
      fh = StringIO.new

      Puppet.settings.setting(:publickeydir).expects(:open_file).with(@public_key_path, 'w').yields fh
      Puppet.settings.setting(:privatekeydir).stubs(:open_file)
      @public_key.expects(:to_pem).returns "my pem"

      @searcher.save(@request)

      expect(fh.string).to eq("my pem")
    end

    it "should destroy the public key when destroying the private key" do
      Puppet::FileSystem::File.stubs(:unlink).with(@private_key_path)
      Puppet::FileSystem::File.stubs(:exist?).with(@private_key_path).returns true
      Puppet::FileSystem::File.expects(:exist?).with(@public_key_path).returns true
      Puppet::FileSystem::File.expects(:unlink).with(@public_key_path)

      @searcher.destroy(@request)
    end

    it "should not fail if the public key does not exist when deleting the private key" do
      Puppet::FileSystem::File.stubs(:unlink).with(@private_key_path)

      Puppet::FileSystem::File.stubs(:exist?).with(@private_key_path).returns true
      Puppet::FileSystem::File.expects(:exist?).with(@public_key_path).returns false
      Puppet::FileSystem::File.expects(:unlink).with(@public_key_path).never

      @searcher.destroy(@request)
    end
  end
end
