require 'spec_helper'

provider_class = Puppet::Type.type(:disable_hotplug).provider(:lnx)

describe provider_class do
  let(:name) { 'global' }

  let(:resource) do
    Puppet::Type.type(:disable_hotplug).new(
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

  it 'Disable hotplug /run' do
    File.stubs(:exist?).with('/run/disable-network-interface-hotplug').returns(false)
    File.stubs(:exist?).with('/var/run/disable-network-interface-hotplug').returns(false)
    File.stubs(:exist?).with('/run').returns(true)
    provider.class.stubs(:udevadm).with('control', '--stop-exec-queue').returns(0)
    FileUtils.stubs(:touch).with('/run/disable-network-interface-hotplug').returns(0)
    provider.create
  end

  it 'Disable hotplug /var/run' do
    File.stubs(:exist?).with('/run/disable-network-interface-hotplug').returns(false)
    File.stubs(:exist?).with('/var/run/disable-network-interface-hotplug').returns(false)
    File.stubs(:exist?).with('/run').returns(false)
    provider.class.stubs(:udevadm).with('control', '--stop-exec-queue').returns(0)
    FileUtils.stubs(:touch).with('/var/run/disable-network-interface-hotplug').returns(0)
    provider.create
  end


  it 'File create error' do
    File.stubs(:exist?).with('/run/disable-network-interface-hotplug').returns(false)
    File.stubs(:exist?).with('/var/run/disable-network-interface-hotplug').returns(false)
    File.stubs(:exist?).with('/run').returns(true)
    provider.class.stubs(:udevadm).with('control', '--stop-exec-queue').returns(0)
    FileUtils.stubs(:touch).with('/run/disable-network-interface-hotplug').raises(Puppet::ExecutionFailure,'')
    expect{provider.create}.to raise_error(Puppet::ExecutionFailure)
  end

  it 'Udevadm error' do
    File.stubs(:exist?).with('/run/disable-network-interface-hotplug').returns(false)
    File.stubs(:exist?).with('/var/run/disable-network-interface-hotplug').returns(false)
    File.stubs(:exist?).with('/run').returns(true)
    provider.class.stubs(:udevadm).with('control', '--stop-exec-queue').raises(Puppet::ExecutionFailure,'')
    expect{provider.create}.to raise_error(Puppet::ExecutionFailure)
  end

  it 'Do nothing' do
    File.stubs(:exist?).with('/run/disable-network-interface-hotplug').returns(true)
    provider.class.expects(:udevadm).with('control', '--stop-exec-queue').never
  end

end
