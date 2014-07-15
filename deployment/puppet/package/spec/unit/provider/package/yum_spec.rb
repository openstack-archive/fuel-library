#! /usr/bin/env ruby
require 'spec_helper'

provider = Puppet::Type.type(:package).provider(:yum)

describe provider do
  before do
    # Create a mock resource
     @resource = stub 'resource'
     @resource.stubs(:[]).with(:name).returns 'mypackage'
     @provider = provider.new(@resource)
     @provider.stubs(:resource).returns @resource
     @provider.stubs(:yum).returns 'yum'
     @provider.stubs(:rpm).returns 'rpm'
     @provider.stubs(:get).with(:name).returns 'mypackage'
     @provider.stubs(:get).with(:version).returns '1'
     @provider.stubs(:get).with(:release).returns '1'
     @provider.stubs(:get).with(:arch).returns 'i386'
  end
  # provider should repond to the following methods
   [:install, :latest, :update, :purge].each do |method|
     it "should have a(n) #{method}" do
       @provider.should respond_to(method)
    end
  end

  describe 'when installing' do
    before(:each) do
      Puppet::Util.stubs(:which).with("rpm").returns("/bin/rpm")
      provider.stubs(:which).with("rpm").returns("/bin/rpm")
      Puppet::Util::Execution.expects(:execute).with(["/bin/rpm", "--version"], {:combine => true, :custom_environment => {}, :failonfail => true}).returns("4.10.1\n").at_most_once
    end

    it 'should call yum install for :installed' do
      @resource.stubs(:should).with(:ensure).returns :installed
      @provider.expects(:yum).with('-d', '0', '-e', '0', '-y', :install, 'mypackage')
      @provider.install
    end

    it 'should use :install to update' do
      @provider.expects(:install)
      @provider.update
    end

    it 'should be able to set version' do
      @resource.stubs(:should).with(:ensure).returns '1.2'
      @provider.expects(:yum).with('-d', '0', '-e', '0', '-y', :install, 'mypackage-1.2')
      @provider.stubs(:query).returns :ensure => '1.2'
      @provider.install
    end

    it 'should be able to downgrade' do
      @resource.stubs(:should).with(:ensure).returns '1.0'
      @provider.expects(:yum).with('-d', '0', '-e', '0', '-y', :downgrade, 'mypackage-1.0')
      @provider.stubs(:query).returns(:ensure => '1.2').then.returns(:ensure => '1.0')
      @provider.install
    end

    it 'should compare tricky versions while downgrading' do
      @resource.stubs(:should).with(:ensure).returns '2014.1.fuel5.0-mira4'
      @provider.stubs(:query).returns(:ensure => '2014.1.1.fuel5.1-mira0').then.returns(:ensure => '2014.1.fuel5.0-mira4')
      @provider.expects(:yum).with('-d', '0', '-e', '0', '-y', :downgrade, 'mypackage-2014.1.fuel5.0-mira4')
      @provider.install
    end

    it 'should compare normal versions while downgrading' do
      @resource.stubs(:should).with(:ensure).returns '2014.1.fuel5.0-mira4'
      @provider.stubs(:query).returns(:ensure => '2014.1.fuel5.1-mira0').then.returns(:ensure => '2014.1.fuel5.0-mira4')
      @provider.expects(:yum).with('-d', '0', '-e', '0', '-y', :downgrade, 'mypackage-2014.1.fuel5.0-mira4')
      @provider.install
    end

    it 'should compare tricky versions while installing' do
      @resource.stubs(:should).with(:ensure).returns '2014.1.1.fuel5.1-mira0'
      @provider.stubs(:query).returns(:ensure => '2014.1.fuel5.0-mira4').then.returns(:ensure => '2014.1.1.fuel5.1-mira0')
      @provider.expects(:yum).with('-d', '0', '-e', '0', '-y', :install, 'mypackage-2014.1.1.fuel5.1-mira0')
      @provider.install
    end

    it 'should compare normal versions while installing' do
      @resource.stubs(:should).with(:ensure).returns '2014.1.fuel5.1-mira0'
      @provider.stubs(:query).returns(:ensure => '2014.1.fuel5.0-mira4').then.returns(:ensure => '2014.1.fuel5.1-mira0')
      @provider.expects(:yum).with('-d', '0', '-e', '0', '-y', :install, 'mypackage-2014.1.fuel5.1-mira0')
      @provider.install
    end
  end

  describe 'when uninstalling' do
    it 'should use erase to purge' do
      @provider.expects(:yum).with('-y', :erase, 'mypackage')
      @provider.purge
    end
  end

  it 'should be versionable' do
    provider.should be_versionable
  end

  describe '#latest' do
    describe 'when latest_info is nil' do
      before :each do
        @provider.stubs(:latest_info).returns(nil)
      end

      it 'raises if ensure is absent and latest_info is nil' do
        @provider.stubs(:properties).returns({:ensure => :absent})

        expect { @provider.latest }.to raise_error(
          Puppet::DevError,
          'Tried to get latest on a missing package'
        )
      end

      it 'returns the ensure value if the package is not already installed' do
        @provider.stubs(:properties).returns({:ensure => '3.4.5'})

        @provider.latest.should == '3.4.5'
      end
    end

    describe 'when latest_info is populated' do
      before :each do
        @provider.stubs(:latest_info).returns({
          :name     => 'mypackage',
          :epoch    => '1',
          :version  => '2.3.4',
          :release  => '5',
          :arch     => 'i686',
          :provider => :yum,
          :ensure   => '2.3.4-5'
        })
      end

      it 'includes the epoch in the version string' do
        @provider.latest.should == '1:2.3.4-5'
      end
    end
  end

  describe 'prefetching' do
    let(:nevra_format) { Puppet::Type::Package::ProviderRpm::NEVRA_FORMAT }

    let(:packages) do
      <<-RPM_OUTPUT
      cracklib-dicts 0 2.8.9 3.3 x86_64 :DESC: The standard CrackLib dictionaries
      basesystem 0 8.0 5.1.1.el5.centos noarch :DESC: The skeleton package which defines a simple Red Hat Enterprise Linux system
      chkconfig 0 1.3.30.2 2.el5 x86_64 :DESC: A system tool for maintaining the /etc/rc*.d hierarchy
      myresource 0 1.2.3.4 5.el4 noarch :DESC: Now with summary
      mysummaryless 0 1.2.3.4 5.el4 noarch :DESC:
      RPM_OUTPUT
    end

    let(:yumhelper_output) do
      <<-YUMHELPER_OUTPUT
 * base: centos.tcpdiag.net
 * extras: centos.mirrors.hoobly.com
 * updates: mirrors.arsc.edu
_pkg nss-tools 0 3.14.3 4.el6_4 x86_64
_pkg pixman 0 0.26.2 5.el6_4 x86_64
_pkg myresource 0 1.2.3.4 5.el4 noarch
_pkg mysummaryless 0 1.2.3.4 5.el4 noarch
     YUMHELPER_OUTPUT
    end

    let(:execute_options) do
      {:failonfail => true, :combine => true, :custom_environment => {}}
    end

    let(:rpm_version) { "RPM version 4.8.0\n" }

    let(:package_type) { Puppet::Type.type(:package) }
    let(:yum_provider) { provider }

    def pretend_we_are_root_for_yum_provider
      Process.stubs(:euid).returns(0)
    end

    def expect_yum_provider_to_provide_rpm
      Puppet::Type::Package::ProviderYum.stubs(:rpm).with('--version').returns(rpm_version)
      Puppet::Type::Package::ProviderYum.expects(:command).with(:rpm).returns("/bin/rpm")
    end

    def expect_execpipe_to_provide_package_info_for_an_rpm_query
      Puppet::Util::Execution.expects(:execpipe).with("/bin/rpm -qa --nosignature --nodigest --qf '#{nevra_format}'").yields(packages)
    end

    def expect_python_yumhelper_call_to_return_latest_info
      Puppet::Type::Package::ProviderYum.expects(:python).with(regexp_matches(/yumhelper.py$/)).returns(yumhelper_output)
    end

    def a_package_type_instance_with_yum_provider_and_ensure_latest(name)
      type_instance = package_type.new(:name => name)
      type_instance.provider = yum_provider.new
      type_instance[:ensure] = :latest
      return type_instance
    end

    before do
      pretend_we_are_root_for_yum_provider
      expect_yum_provider_to_provide_rpm
      expect_execpipe_to_provide_package_info_for_an_rpm_query
      expect_python_yumhelper_call_to_return_latest_info
    end

    it "injects latest provider info into passed resources when prefetching" do
      myresource = a_package_type_instance_with_yum_provider_and_ensure_latest('myresource')
      mysummaryless = a_package_type_instance_with_yum_provider_and_ensure_latest('mysummaryless')

      yum_provider.prefetch({ "myresource" => myresource, "mysummaryless" => mysummaryless })

      expect(@logs.map(&:message).grep(/^Failed to match rpm line/)).to be_empty
      expect(myresource.provider.latest_info).to eq({
        :name=>"myresource",
        :epoch=>"0",
        :version=>"1.2.3.4",
        :release=>"5.el4",
        :arch=>"noarch",
        :provider=>:yum,
        :ensure=>"1.2.3.4-5.el4"
      })
    end
  end

  describe "with transactional rollback support" do
    let(:yum_options) { %w(-d 0 -e 0 -y) }
    let(:file_dir) { '/var/lib/puppet/rollback' }
    let(:rollback_file_down) { '/var/lib/puppet/rollback/mypackage_2.0_1.0.yaml' }
    let(:rollback_file_up) { '/var/lib/puppet/rollback/mypackage_1.0_2.0.yaml' }

    let(:before) do
      {
        'otherpkg' => '1',
        'asdf' => '1.0',
        'asdf-lib' => '1.0',
        'asdf-old-dep' => '1',
      }
    end

    let (:after) do
      {
        'otherpkg' => '1',
        'asdf' => '2.0',
        'asdf-lib' => '2.0',
        'asdf-new-dep' => '1',
      }
    end

    let (:diff) do
      {
        'installed' => {
            'asdf' => '2.0',
            'asdf-lib' => '2.0',
            'asdf-new-dep' => '1'
        },
        'removed' => {
            'asdf' => '1.0',
            'asdf-lib' => '1.0',
            'asdf-old-dep' => '1'
        }
      }
    end

    after(:each) do
      @provider.properties
      @provider.install
    end

    before(:each) do
      File.stubs(:directory?).with(file_dir).returns true
    end

    describe "when updating" do
      before(:each) {
        @provider.stubs(:read_diff).returns nil
      }

      it "saves diff only when version is changing and there is no rollback file" do
        @resource.stubs(:should).with(:ensure).returns '2.0'
        @provider.stubs(:query).returns(:ensure => '1.0')
        @provider.stubs(:check_query).returns(:ensure => '2.0')
        @provider.stubs(:yum_with_changes).with(yum_options, :install, 'mypackage-2.0')
        @provider.stubs(:make_package_diff).times(1)
        @provider.stubs(:save_diff).times(1)
      end

      it "doesn't save diff when package is being installed the first time" do
        @resource.stubs(:should).with(:ensure).returns :present
        @provider.stubs(:query).returns(:ensure => :absent)
        @provider.stubs(:yum).with(*yum_options, :install, 'mypackage')
        @provider.stubs(:save_diff).times(0)
      end

      it "saves correct diff to the rollback file" do
        @resource.stubs(:should).with(:ensure).returns '2.0'
        @provider.stubs(:query).returns(:ensure => '1.0')
        @provider.stubs(:check_query).returns(:ensure => '2.0')
        @provider.stubs(:yum_with_changes).with(yum_options, :install, 'mypackage-2.0').returns([before, after])
        @provider.stubs(:save_diff).with(rollback_file_up, diff)
      end
    end

    describe "when rolling back" do
      it 'only when rollback file is found' do
        @resource.stubs(:should).with(:ensure).returns '1.0'
        @provider.stubs(:query).returns(:ensure => '2.0')
        @provider.stubs(:check_query).returns(:ensure => '1.0')
        @provider.stubs(:read_diff).with(rollback_file_up).returns nil
        @provider.stubs(:yum).with(*yum_options, :downgrade, 'mypackage-1.0')
        @provider.stubs(:save_diff).times(1)
      end

      it "calls apt-get with correct package list" do
        @resource.stubs(:should).with(:ensure).returns '1.0'
        @provider.stubs(:query).returns(:ensure => '2.0')
        @provider.stubs(:check_query).returns(:ensure => '1.0')
        @provider.stubs(:read_diff).with(rollback_file_up).returns diff
        @provider.stubs(:yum_shell).times(1)
        @provider.stubs(:save_diff).times(0)
      end
    end

  end

end
