#! /usr/bin/env ruby
require 'spec_helper'

provider = Puppet::Type.type(:package).provider(:apt)

describe provider do
  before do
    @resource = stub 'resource', :[] => "asdf"
    @provider = provider.new(@resource)

    @fakeresult = <<-EOF
install ok installed asdf 1.0 "asdf summary
 asdf multiline description
 with multiple lines
EOF
  end

  it "should be versionable" do
    provider.should be_versionable
  end

  it "should use :install to update" do
    @provider.expects(:install)
    @provider.update
  end

  it "should use 'apt-get remove' to uninstall" do
    @provider.expects(:aptget).with("-y", "-q", :remove, "asdf")

    @provider.uninstall
  end

  it "should use 'apt-get purge' and 'dpkg purge' to purge" do
    @provider.expects(:aptget).with("-y", "-q", :remove, "--purge", "asdf")
    @provider.expects(:dpkg).with("--purge", "asdf")

    @provider.purge
  end

  it "should use 'apt-cache policy' to determine the latest version of a package" do
    @provider.expects(:aptcache).with(:policy, "asdf").returns "asdf:
Installed: 1:1.0
Candidate: 1:1.1
Version table:
1:1.0
  650 http://ftp.osuosl.org testing/main Packages
*** 1:1.1
  100 /var/lib/dpkg/status"

    @provider.latest.should == "1:1.1"
  end

  it "should print and error and return nil if no policy is found" do
    @provider.expects(:aptcache).with(:policy, "asdf").returns "asdf:"

    @provider.expects(:err)
    @provider.latest.should be_nil
  end

  it "should be able to preseed" do
    @provider.should respond_to(:run_preseed)
  end

  it "should preseed with the provided responsefile when preseeding is called for" do
    @resource.expects(:[]).with(:responsefile).returns "/my/file"
    Puppet::FileSystem::File.expects(:exist?).with("/my/file").returns true

    @provider.expects(:info)
    @provider.expects(:preseed).with("/my/file")

    @provider.run_preseed
  end

  it "should not preseed if no responsefile is provided" do
    @resource.expects(:[]).with(:responsefile).returns nil

    @provider.expects(:info)
    @provider.expects(:preseed).never

    @provider.run_preseed
  end

  describe "when installing" do
    it "should preseed if a responsefile is provided" do
      @resource.expects(:[]).with(:responsefile).returns "/my/file"
      @provider.expects(:run_preseed)

      @provider.stubs(:aptget)
      @provider.install
    end

    it "should check for a cdrom" do
      @provider.expects(:checkforcdrom)

      @provider.stubs(:aptget)
      @provider.install
    end

    it "should use 'apt-get install' with the package name if no version is asked for" do
      @resource.expects(:[]).with(:ensure).returns :installed
      @provider.expects(:aptget).with { |*command| command[-1] == "asdf" and command[-2] == :install }

      @provider.install
    end

    it "should specify the package version if one is asked for" do
      @resource.expects(:[]).with(:ensure).returns "1.0"
      @provider.expects(:aptget).with { |*command| command[-1] == "asdf=1.0" }

      @provider.install
    end

    it "should use --force-yes if a package version is specified" do
      @resource.expects(:[]).with(:ensure).returns "1.0"
      @provider.expects(:aptget).with { |*command| command.include?("--force-yes") }

      @provider.install
    end

    it "should do a quiet install" do
      @provider.expects(:aptget).with { |*command| command.include?("-q") }

      @provider.install
    end

    it "should default to 'yes' for all questions" do
      @provider.expects(:aptget).with { |*command| command.include?("-y") }

      @provider.install
    end

    it "should keep config files if asked" do
      @resource.expects(:[]).with(:configfiles).returns :keep
      @provider.expects(:aptget).with { |*command| command.include?("DPkg::Options::=--force-confold") }

      @provider.install
    end

    it "should replace config files if asked" do
      @resource.expects(:[]).with(:configfiles).returns :replace
      @provider.expects(:aptget).with { |*command| command.include?("DPkg::Options::=--force-confnew") }

      @provider.install
    end
  end

  describe "with transactional rollback support" do

    let(:file_dir) { '/var/lib/puppet/rollback' }
    let(:rollback_file_up) { '/var/lib/puppet/rollback/asdf_1.0_2.0.yaml' }
    let(:rollback_file_down) { '/var/lib/puppet/rollback/asdf_2.0_1.0.yaml' }

    let(:before) do
      {
        'otherpkg' => '1',
        'asdf' => '1.0',
        'asdf-lib' => '1.0',
        'asdf-old-dep' => '1',
      }
    end

    let(:after) do
      {
        'otherpkg' => '1',
        'asdf' => '2.0',
        'asdf-lib' => '2.0',
        'asdf-new-dep' => '1',
      }
    end

    let(:diff) do
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

    let(:pkgs) { [ 'asdf=1.0', 'asdf-lib=1.0', 'asdf-old-dep=1', 'asdf-new-dep-' ] }

    after(:each) do
      @provider.properties
      @provider.install
    end

    before(:each) do
      File.stubs(:directory?).with(file_dir).returns true
    end

    describe "when updating" do
      before(:each) do
        @provider.stubs(:read_diff).returns nil
      end

      it "saves diff only when version is changing and there is no rollback file" do
        @resource.stubs(:[]).with(:ensure).returns "2.0"
        @provider.stubs(:query).returns({:ensure => '1.0', :status => '1.0', :name => 'asdf', :error => 'ok'})
        @provider.stubs(:read_diff).with(rollback_file_down).returns nil
        @provider.stubs(:aptget_with_changes).with { |command| command[-1] == "asdf=2.0" }
        @provider.stubs(:make_package_diff).times(1)
        @provider.stubs(:save_diff).times(1)
      end

      it "doesn't save diff when package is being installed the first time" do
        @resource.stubs(:[]).with(:ensure).returns :present
        @provider.stubs(:query).returns({:ensure => :absent, :status => 'missing', :name => 'asdf', :error => 'ok'})
        @provider.stubs(:aptget).with { |*command| command[-1] == "asdf" }
        @provider.stubs(:save_diff).times(0)
      end

      it "saves correct diff to the rollback file" do
        @resource.stubs(:[]).with(:ensure).returns "2.0"
        @provider.stubs(:query).returns({:ensure => '1.0', :status => '1.0', :name => 'asdf', :error => 'ok'})
        @provider.stubs(:aptget_with_changes).with { |command| command[-1] == "asdf=2.0" }.returns([before, after])
        @provider.stubs(:save_diff).with(rollback_file_up, diff)
      end
    end

    describe "when rolling back" do
      it 'only when rollback file is found' do
        @resource.stubs(:[]).with(:ensure).returns "1.0"
        @provider.stubs(:query).returns({:ensure => '2.0', :status => '2.0', :name => 'asdf', :error => 'ok'})
        @provider.stubs(:read_diff).with(rollback_file_up).returns nil
        @provider.stubs(:aptget).with { |*command| command[-2,2] == [:install, 'asdf=1.0'] }
        @provider.stubs(:save_diff).times(1)
      end

      it "calls apt-get with correct package list" do
        @resource.stubs(:[]).with(:ensure).returns "1.0"
        @provider.stubs(:query).returns({:ensure => '2.0', :status => '1.0', :name => 'asdf', :error => 'ok'})
        @provider.stubs(:read_diff).with(rollback_file_up).returns(diff)
        @provider.stubs(:aptget).with { |*command| command[-5,5] == [ :install ] + pkgs }
      end
    end

  end

end
