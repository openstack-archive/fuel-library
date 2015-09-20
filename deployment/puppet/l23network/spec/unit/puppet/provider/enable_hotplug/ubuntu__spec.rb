require 'spec_helper'

provider_class = Puppet::Type.type(:enable_hotplug).provider(:ubuntu)

describe provider_class do
  let(:name) { 'global' }

  let(:resource) do
    Puppet::Type.type(:enable_hotplug).new(
      :name        => name,
      :ensure      => 'present',
    )
  end

  let(:provider) do
    provider = provider_class.new
    provider.resource = resource
    provider
  end

  before(:each) do
    puppet_debug_override()
  end

  it 'Enable hotplug' do
    File.stubs(:exist?).with('/etc/network/disable-network-interface-hotplug').returns(true)
    FileUtils.stubs(:rm).with('/etc/network/disable-network-interface-hotplug').returns(0)
    provider.class.stubs(:udevadm).with('control', '--start-exec-queue').returns(0)
    provider.create
  end

  it 'Udevadm error' do
    FileUtils.stubs(:rm).with('/etc/network/disable-network-interface-hotplug').returns(0)
    provider.class.stubs(:udevadm).with('control', '--start-exec-queue').raises(Puppet::ExecutionFailure,'')
    expect{provider.create}.to raise_error(Puppet::ExecutionFailure)
  end

  it 'File remove error' do
    FileUtils.stubs(:rm).with('/etc/network/disable-network-interface-hotplug').raises(Puppet::ExecutionFailure,'')
    expect{provider.create}.to raise_error(Puppet::ExecutionFailure)
  end

  it 'Do nothing' do
    File.stubs(:exist?).with('/etc/network/disable-network-interface-hotplug').returns(false)
    provider.expects(:udevadm).with('control', '--start-exec-queue').never
  end

end

# vim: set ts=2 sw=2 et
