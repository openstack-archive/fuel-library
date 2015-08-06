#! /usr/bin/env ruby
require 'spec_helper'
require 'stringio'

provider = Puppet::Type.type(:package).provider(:pacman)

describe provider do
  let(:no_extra_options) { { :failonfail => true, :combine => true, :custom_environment => {} } }
  let(:executor) { Puppet::Util::Execution }
  let(:resolver) { Puppet::Util }

  before do
    resolver.stubs(:which).with('/usr/bin/pacman').returns('/usr/bin/pacman')
    provider.stubs(:which).with('/usr/bin/pacman').returns('/usr/bin/pacman')
    @resource = Puppet::Type.type(:package).new(:name => 'package')
    @provider = provider.new(@resource)
  end

  describe "when installing" do
    before do
      @provider.stubs(:query).returns({
        :ensure => '1.0'
      })
    end

    it "should call pacman to install the right package quietly" do
      executor.
        expects(:execute).
        at_least_once.
        with(["/usr/bin/pacman", "--noconfirm", "--noprogressbar", "-Sy", @resource[:name]], no_extra_options).
        returns ""

      @provider.install
    end

    it "should raise an ExecutionFailure if the installation failed" do
      executor.stubs(:execute).returns("")
      @provider.expects(:query).returns(nil)

      lambda { @provider.install }.should raise_exception(Puppet::ExecutionFailure)
    end

    context "when :source is specified" do
      before :each do
        @install = sequence("install")
      end

      context "recognizable by pacman" do
        %w{
          /some/package/file
          http://some.package.in/the/air
          ftp://some.package.in/the/air
        }.each do |source|
          it "should install #{source} directly" do
            @resource[:source] = source

            executor.expects(:execute).
              with(all_of(includes("-Sy"), includes("--noprogressbar")), no_extra_options).
              in_sequence(@install).
              returns("")

            executor.expects(:execute).
              with(all_of(includes("-U"), includes(source)), no_extra_options).
              in_sequence(@install).
              returns("")

            @provider.install
          end
        end
      end

      context "as a file:// URL" do
        before do
          @package_file = "file:///some/package/file"
          @actual_file_path = "/some/package/file"
          @resource[:source] = @package_file
        end

        it "should install from the path segment of the URL" do
          executor.expects(:execute).
            with(all_of(includes("-Sy"),
                        includes("--noprogressbar"),
                        includes("--noconfirm")),
                 no_extra_options).
            in_sequence(@install).
            returns("")

          executor.expects(:execute).
            with(all_of(includes("-U"), includes(@actual_file_path)), no_extra_options).
            in_sequence(@install).
            returns("")

          @provider.install
        end
      end

      context "as a puppet URL" do
        before do
          @resource[:source] = "puppet://server/whatever"
        end

        it "should fail" do
          lambda { @provider.install }.should raise_error(Puppet::Error)
        end
      end

      context "as a malformed URL" do
        before do
          @resource[:source] = "blah://"
        end

        it "should fail" do
          lambda { @provider.install }.should raise_error(Puppet::Error)
        end
      end
    end
  end

  describe "when updating" do
    it "should call install" do
      @provider.expects(:install).returns("install return value")
      @provider.update.should == "install return value"
    end
  end

  describe "when uninstalling" do
    it "should call pacman to remove the right package quietly" do
      executor.
        expects(:execute).
        with(["/usr/bin/pacman", "--noconfirm", "--noprogressbar", "-R", @resource[:name]], no_extra_options).
        returns ""

      @provider.uninstall
    end
  end

  describe "when querying" do
    it "should query pacman" do
      executor.
        expects(:execute).
        with(["/usr/bin/pacman", "-Qi", @resource[:name]], no_extra_options)
      @provider.query
    end

    it "should return the version" do
      query_output = <<EOF
Name           : package
Version        : 1.01.3-2
URL            : http://www.archlinux.org/pacman/
Licenses       : GPL
Groups         : base
Provides       : None
Depends On     : bash  libarchive>=2.7.1  libfetch>=2.25  pacman-mirrorlist
Optional Deps  : fakeroot: for makepkg usage as normal user
                 curl: for rankmirrors usage
Required By    : None
Conflicts With : None
Replaces       : None
Installed Size : 2352.00 K
Packager       : Dan McGee <dan@archlinux.org>
Architecture   : i686
Build Date     : Sat 22 Jan 2011 03:56:41 PM EST
Install Date   : Thu 27 Jan 2011 06:45:49 AM EST
Install Reason : Explicitly installed
Install Script : Yes
Description    : A library-based package manager with dependency support
EOF

      executor.expects(:execute).returns(query_output)
      @provider.query.should == {:ensure => "1.01.3-2"}
    end

    it "should return a nil if the package isn't found" do
      executor.expects(:execute).returns("")
      @provider.query.should be_nil
    end

    it "should return a hash indicating that the package is missing on error" do
      executor.expects(:execute).raises(Puppet::ExecutionFailure.new("ERROR!"))
      @provider.query.should == {
        :ensure => :purged,
        :status => 'missing',
        :name => @resource[:name],
        :error => 'ok',
      }
    end
  end

  describe "when fetching a package list" do
    it "should query pacman" do
      provider.expects(:execpipe).with(["/usr/bin/pacman", '-Q'])
      provider.instances
    end

    it "should return installed packages with their versions" do
      provider.expects(:execpipe).yields(StringIO.new("package1 1.23-4\npackage2 2.00\n"))
      packages = provider.instances

      packages.length.should == 2

      packages[0].properties.should == {
        :provider => :pacman,
        :ensure => '1.23-4',
        :name => 'package1'
      }

      packages[1].properties.should == {
        :provider => :pacman,
        :ensure => '2.00',
        :name => 'package2'
      }
    end

    it "should return nil on error" do
      provider.expects(:execpipe).raises(Puppet::ExecutionFailure.new("ERROR!"))
      provider.instances.should be_nil
    end

    it "should warn on invalid input" do
      provider.expects(:execpipe).yields(StringIO.new("blah"))
      provider.expects(:warning).with("Failed to match line blah")
      provider.instances.should == []
    end
  end

  describe "when determining the latest version" do
    it "should refresh package list" do
      get_latest_version = sequence("get_latest_version")
      executor.
        expects(:execute).
        in_sequence(get_latest_version).
        with(['/usr/bin/pacman', '-Sy'], no_extra_options)

      executor.
        stubs(:execute).
        in_sequence(get_latest_version).
        returns("")

      @provider.latest
    end

    it "should get query pacman for the latest version" do
      get_latest_version = sequence("get_latest_version")
      executor.
        stubs(:execute).
        in_sequence(get_latest_version)

      executor.
        expects(:execute).
        in_sequence(get_latest_version).
        with(['/usr/bin/pacman', '-Sp', '--print-format', '%v', @resource[:name]], no_extra_options).
        returns("")

      @provider.latest
    end

    it "should return the version number from pacman" do
      executor.
        expects(:execute).
        at_least_once().
        returns("1.00.2-3\n")

      @provider.latest.should == "1.00.2-3"
    end
  end
end
