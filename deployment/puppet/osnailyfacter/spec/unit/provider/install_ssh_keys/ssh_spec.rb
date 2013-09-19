require 'spec_helper'
require 'fakefs/spec_helpers'

describe Puppet::Type.type(:install_ssh_keys).provider(:ssh) do
  include FakeFS::SpecHelpers

  before :each do
    @name             = 'test'
    @private_key_path = '/private_key_path' 
    @public_key_path  = '/public_key_path'
    @id_rsa           = '/root/.ssh/id_rsa'
    @id_rsa_pub       = '/root/.ssh/id_rsa.pub'
    @authorized_keys  = '/root/.ssh/authorized_keys'
    @user             = 'root'
    File.open(@private_key_path, 'w') { |file| file.write("private\n") }
    File.open(@public_key_path, 'w') { |file| file.write("public\n") }
    FileUtils.mkdir('/root')
    FileUtils.mkdir('/root/.ssh')
    File.open(@authorized_keys, 'w') { |file| file.write("key1\nkey2\n") }
  end

  let(:resource) { Puppet::Type.type(:install_ssh_keys).new(
      :ensure           => :present,
      :name             => @name,
      :private_key_path => @private_key_path,
      :public_key_path  => @public_key_path,
      :user             => @user,
      :provider         => :ssh
    )
  }
  let(:provider) { resource.provider }

  it 'checks that resource exist' do
    File.open(@id_rsa, 'w') { |file| file.write("private\n") }
    File.open(@id_rsa_pub, 'w') { |file| file.write("public\n") }
    File.open(@authorized_keys, 'w') { |file| file.write("key1\nkey2\npublic\n") }
    provider.exists?().should be_true
  end
  
  it 'checks that resource does not exist' do
    provider.exists?().should be_false
  end

  it 'creates new resource' do
    provider.create
    File.read(@id_rsa).should == "private\n"
    File.read(@id_rsa_pub).should == "public\n"
    authkeys = File.read(@authorized_keys)
    authkeys.grep("public\n").any?.should be_true
    authkeys.grep("key1\n").any?.should be_true
    authkeys.grep("key2\n").any?.should be_true
  end
  
  it 'removes resource' do
    File.open(@private_key_path, 'w') { |file| file.write("private\n") }
    File.open(@public_key_path, 'w') { |file| file.write("public\n") }
    File.open(@public_key_path, 'w') { |file| file.write("key1\nkey2\npublic\n") }
    provider.destroy
    File.exists?(@id_rsa).should be_false
    File.exists?(@id_rsa_pub).should be_false
    authkeys = File.read(@authorized_keys)
    authkeys.grep("public\n").any?.should be_false
    authkeys.grep("key1\n").any?.should be_true
    authkeys.grep("key2\n").any?.should be_true
  end

end
