require 'spec_helper'

describe Puppet::Type.type(:package).provider(:apt_fuel) do
  let(:resource) do
    Puppet::Type.type(:package).new(
        :ensure => :present,
        :name => 'test',
        :provider => :apt_fuel,
    )
  end

  let(:provider) do
    resource.provider
  end

  subject { provider }

  before(:each) do
    puppet_debug_override
    subject.stubs(:lock_sleep).returns(0)
    subject.stubs(:retry_sleep).returns(0)
    subject.stubs(:timeout).returns(300)
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should check for lock file to be free before installing a package' do
    subject.expects(:locked?).returns(false)
    subject.expects(:aptget).returns(true)
    subject.install
  end

  it 'should wait unless lock file is free' do
    subject.expects(:locked?).returns(true, false).twice
    subject.expects(:aptget).returns(true)
    subject.install
  end

  it 'should fail if lock timeout is exceeded' do
    subject.stubs(:lock_sleep).returns(2)
    subject.stubs(:timeout).returns(1)
    subject.stubs(:locked?).returns(true, true, false)
    subject.stubs(:aptget).returns(true)
    expect do
      subject.install
    end.to raise_error Timeout::Error
  end

  it 'should retry the failed installation attempts' do
    subject.stubs(:locked?).returns(false)
    subject.expects(:aptget).
        with('-q', '-y', '-o', 'DPkg::Options::=--force-confold', '--force-yes', :install, 'test').
        raises(Puppet::ExecutionFailure, 'installation failed').times(3)
    subject.expects(:aptget).with('-q', '-y', :update).times(2)
    expect do
      subject.install
    end.to raise_error Puppet::ExecutionFailure, 'installation failed'
  end

  it 'should be able to succeed after failing' do
    subject.stubs(:locked?).returns(false)
    subject.expects(:aptget).
        with('-q', '-y', '-o', 'DPkg::Options::=--force-confold', '--force-yes', :install, 'test').
        raises(Puppet::ExecutionFailure, 'installation failed').then.returns(true).times(2)
    subject.expects(:aptget).with('-q', '-y', :update).times(1)
    subject.install
  end

end
