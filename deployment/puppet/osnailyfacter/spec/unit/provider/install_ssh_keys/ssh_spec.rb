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
    expect(provider.exists?).to eq true
  end
  
  it 'checks that resource does not exist' do
    expect(provider.exists?).to eq false
  end

  it 'creates new resource' do
    provider.create
    File.read(@id_rsa).should == "private\n"
    File.read(@id_rsa_pub).should == "public\n"
    authkeys = File.read(@authorized_keys)
    keys = authkeys.split("\n")
    expect(keys).to include 'public'
    expect(keys).to include 'key1'
    expect(keys).to include 'key2'
  end
  
  it 'removes resource' do
    File.open(@private_key_path, 'w') { |file| file.write("private\n") }
    File.open(@public_key_path, 'w') { |file| file.write("public\n") }
    File.open(@public_key_path, 'w') { |file| file.write("key1\nkey2\npublic\n") }
    provider.destroy
    expect(File.exists?(@id_rsa)).to eq false
    expect(File.exists?(@id_rsa_pub)).to eq false
    authkeys = File.read(@authorized_keys)
    keys = authkeys.split("\n")
    expect(keys).not_to include 'public'
    expect(keys).to include 'key1'
    expect(keys).to include 'key2'
  end

end
