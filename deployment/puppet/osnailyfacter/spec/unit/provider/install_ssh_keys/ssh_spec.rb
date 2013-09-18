require 'puppet'
require 'test/unit'
require 'mocha/setup'
require 'puppet/provider/install_ssh_keys/ssh'

describe 'Puppet::Type.type(:install_ssh_keys)' do
  before :all do
    type_class = Puppet::Type::Install_ssh_keys.new(:name => 'test',
                                                  :user => 'root')
    @provider_class = Puppet::Type.type(:install_ssh_keys).provider(:ssh).new(type_class)
  end

  it 'should return false if resource exist' do
    #File.stub!(:exists?).and_return(true)
    #File.stub!(:read).and_return(true)
    #.stub!(:grep).and_return(true).stub!(:any?).and_return(true)
    #@provider_class.stub!(:authkey_present?).and_return(true)
    @provider_class.exists?.should be false
  end

  it 'should be correct ssh dir' do
    @provider_class.sshdir == '/root/.ssh'
  end
end
