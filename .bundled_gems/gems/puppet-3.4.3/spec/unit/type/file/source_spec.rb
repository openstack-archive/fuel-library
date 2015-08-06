#! /usr/bin/env ruby
require 'spec_helper'
require 'uri'

source = Puppet::Type.type(:file).attrclass(:source)
describe Puppet::Type.type(:file).attrclass(:source) do
  include PuppetSpec::Files

  before do
    # Wow that's a messy interface to the resource.
    @environment = "myenv"
    @resource = stub 'resource', :[]= => nil, :property => nil, :catalog => stub("catalog", :dependent_data_expired? => false, :environment => @environment), :line => 0, :file => ''
    @foobar = make_absolute("/foo/bar baz")
    @feebooz = make_absolute("/fee/booz baz")

    @foobar_uri  = URI.unescape(Puppet::Util.path_to_uri(@foobar).to_s)
    @feebooz_uri = URI.unescape(Puppet::Util.path_to_uri(@feebooz).to_s)
  end

  it "should be a subclass of Parameter" do
    source.superclass.must == Puppet::Parameter
  end

  describe "#validate" do
    let(:path) { tmpfile('file_source_validate') }
    let(:resource) { Puppet::Type.type(:file).new(:path => path) }

    it "should fail if the set values are not URLs" do
      URI.expects(:parse).with('foo').raises RuntimeError

      lambda { resource[:source] = %w{foo} }.must raise_error(Puppet::Error)
    end

    it "should fail if the URI is not a local file, file URI, or puppet URI" do
      lambda { resource[:source] = %w{http://foo/bar} }.must raise_error(Puppet::Error, /Cannot use URLs of type 'http' as source for fileserving/)
    end

    it "should strip trailing forward slashes", :unless => Puppet.features.microsoft_windows? do
      resource[:source] = "/foo/bar\\//"
      resource[:source].should == %w{file:/foo/bar\\}
    end

    it "should strip trailing forward and backslashes", :if => Puppet.features.microsoft_windows? do
      resource[:source] = "X:/foo/bar\\//"
      resource[:source].should == %w{file:/X:/foo/bar}
    end

    it "should accept an array of sources" do
      resource[:source] = %w{file:///foo/bar puppet://host:8140/foo/bar}
      resource[:source].should == %w{file:///foo/bar puppet://host:8140/foo/bar}
    end

    it "should accept file path characters that are not valid in URI" do
      resource[:source] = 'file:///foo bar'
    end

    it "should reject relative URI sources" do
      lambda { resource[:source] = 'foo/bar' }.must raise_error(Puppet::Error)
    end

    it "should reject opaque sources" do
      lambda { resource[:source] = 'mailto:foo@com' }.must raise_error(Puppet::Error)
    end

    it "should accept URI authority component" do
      resource[:source] = 'file://host/foo'
      resource[:source].should == %w{file://host/foo}
    end

    it "should accept when URI authority is absent" do
      resource[:source] = 'file:///foo/bar'
      resource[:source].should == %w{file:///foo/bar}
    end
  end

  describe "#munge" do
    let(:path) { tmpfile('file_source_munge') }
    let(:resource) { Puppet::Type.type(:file).new(:path => path) }

    it "should prefix file scheme to absolute paths" do
      resource[:source] = path
      resource[:source].should == [URI.unescape(Puppet::Util.path_to_uri(path).to_s)]
    end

    %w[file puppet].each do |scheme|
      it "should not prefix valid #{scheme} URIs" do
        resource[:source] = "#{scheme}:///foo bar"
        resource[:source].should == ["#{scheme}:///foo bar"]
      end
    end
  end

  describe "when returning the metadata" do
    before do
      @metadata = stub 'metadata', :source= => nil
      @resource.stubs(:[]).with(:links).returns :manage
    end

    it "should return already-available metadata" do
      @source = source.new(:resource => @resource)
      @source.metadata = "foo"
      @source.metadata.should == "foo"
    end

    it "should return nil if no @should value is set and no metadata is available" do
      @source = source.new(:resource => @resource)
      @source.metadata.should be_nil
    end

    it "should collect its metadata using the Metadata class if it is not already set" do
      @source = source.new(:resource => @resource, :value => @foobar)
      Puppet::FileServing::Metadata.indirection.expects(:find).with(@foobar_uri, :environment => @environment, :links => :manage).returns @metadata
      @source.metadata
    end

    it "should use the metadata from the first found source" do
      metadata = stub 'metadata', :source= => nil
      @source = source.new(:resource => @resource, :value => [@foobar, @feebooz])
      Puppet::FileServing::Metadata.indirection.expects(:find).with(@foobar_uri, :environment => @environment, :links => :manage).returns nil
      Puppet::FileServing::Metadata.indirection.expects(:find).with(@feebooz_uri, :environment => @environment, :links => :manage).returns metadata
      @source.metadata.should equal(metadata)
    end

    it "should store the found source as the metadata's source" do
      metadata = mock 'metadata'
      @source = source.new(:resource => @resource, :value => @foobar)
      Puppet::FileServing::Metadata.indirection.expects(:find).with(@foobar_uri, :environment => @environment, :links => :manage).returns metadata

      metadata.expects(:source=).with(@foobar_uri)
      @source.metadata
    end

    it "should fail intelligently if an exception is encountered while querying for metadata" do
      @source = source.new(:resource => @resource, :value => @foobar)
      Puppet::FileServing::Metadata.indirection.expects(:find).with(@foobar_uri, :environment => @environment, :links => :manage).raises RuntimeError

      @source.expects(:fail).raises ArgumentError
      lambda { @source.metadata }.should raise_error(ArgumentError)
    end

    it "should fail if no specified sources can be found" do
      @source = source.new(:resource => @resource, :value => @foobar)
      Puppet::FileServing::Metadata.indirection.expects(:find).with(@foobar_uri, :environment => @environment, :links => :manage).returns nil

      @source.expects(:fail).raises RuntimeError

      lambda { @source.metadata }.should raise_error(RuntimeError)
    end
  end

  it "should have a method for setting the desired values on the resource" do
    source.new(:resource => @resource).must respond_to(:copy_source_values)
  end

  describe "when copying the source values" do
    before do
      @resource = Puppet::Type.type(:file).new :path => @foobar

      @source = source.new(:resource => @resource)
      @metadata = stub 'metadata', :owner => 100, :group => 200, :mode => "173", :checksum => "{md5}asdfasdf", :ftype => "file", :source => @foobar
      @source.stubs(:metadata).returns @metadata

      Puppet.features.stubs(:root?).returns true
    end

    it "should fail if there is no metadata" do
      @source.stubs(:metadata).returns nil
      @source.expects(:devfail).raises ArgumentError
      lambda { @source.copy_source_values }.should raise_error(ArgumentError)
    end

    it "should set :ensure to the file type" do
      @metadata.stubs(:ftype).returns "file"

      @source.copy_source_values
      @resource[:ensure].must == :file
    end

    it "should not set 'ensure' if it is already set to 'absent'" do
      @metadata.stubs(:ftype).returns "file"

      @resource[:ensure] = :absent
      @source.copy_source_values
      @resource[:ensure].must == :absent
    end

    describe "and the source is a file" do
      before do
        @metadata.stubs(:ftype).returns "file"
        Puppet.features.stubs(:microsoft_windows?).returns false
      end

      it "should copy the metadata's owner, group, checksum, and mode to the resource if they are not set on the resource" do
        @source.copy_source_values

        @resource[:owner].must == 100
        @resource[:group].must == 200
        @resource[:mode].must == "173"

        # Metadata calls it checksum, we call it content.
        @resource[:content].must == @metadata.checksum
      end

      it "should not copy the metadata's owner, group, checksum and mode to the resource if they are already set" do
        @resource[:owner] = 1
        @resource[:group] = 2
        @resource[:mode] = 3
        @resource[:content] = "foobar"

        @source.copy_source_values

        @resource[:owner].must == 1
        @resource[:group].must == 2
        @resource[:mode].must == "3"
        @resource[:content].should_not == @metadata.checksum
      end

      describe "and puppet is not running as root" do
        before do
          Puppet.features.stubs(:root?).returns false
        end

        it "should not try to set the owner" do
          @source.copy_source_values
          @resource[:owner].should be_nil
        end

        it "should not try to set the group" do
          @source.copy_source_values
          @resource[:group].should be_nil
        end
      end

      context "when source_permissions is `use_when_creating`" do
        before :each do
          @resource[:source_permissions] = "use_when_creating"
          Puppet.features.expects(:root?).returns true
          @source.stubs(:local?).returns(false)
        end

        context "when managing a new file" do
          it "should copy owner and group from local sources" do
            @source.stubs(:local?).returns true

            @source.copy_source_values

            @resource[:owner].must == 100
            @resource[:group].must == 200
            @resource[:mode].must == "173"
          end

          it "copies the remote owner" do
            @source.copy_source_values

            @resource[:owner].must == 100
          end

          it "copies the remote group" do
            @source.copy_source_values

            @resource[:group].must == 200
          end

          it "copies the remote mode" do
            @source.copy_source_values

            @resource[:mode].must == "173"
          end
        end

        context "when managing an existing file" do
          before :each do
            Puppet::FileSystem::File.stubs(:exist?).with(@resource[:path]).returns(true)
          end

          it "should not copy owner, group or mode from local sources" do
            @source.stubs(:local?).returns true

            @source.copy_source_values

            @resource[:owner].must be_nil
            @resource[:group].must be_nil
            @resource[:mode].must be_nil
          end

          it "preserves the local owner" do
            @source.copy_source_values

            @resource[:owner].must be_nil
          end

          it "preserves the local group" do
            @source.copy_source_values

            @resource[:group].must be_nil
          end

          it "preserves the local mode" do
            @source.copy_source_values

            @resource[:mode].must be_nil
          end
        end
      end

      context "when source_permissions is `ignore`" do
        before :each do
          @resource[:source_permissions] = "ignore"
          @source.stubs(:local?).returns(false)
          Puppet.features.expects(:root?).returns true
        end

        it "should not copy owner, group or mode from local sources" do
          @source.stubs(:local?).returns true

          @source.copy_source_values

          @resource[:owner].must be_nil
          @resource[:group].must be_nil
          @resource[:mode].must be_nil
        end

        it "preserves the local owner" do
          @source.copy_source_values

          @resource[:owner].must be_nil
        end

        it "preserves the local group" do
          @source.copy_source_values

          @resource[:group].must be_nil
        end

        it "preserves the local mode" do
          @source.copy_source_values

          @resource[:mode].must be_nil
        end
      end

      describe "on Windows" do
        before :each do
          Puppet.features.stubs(:microsoft_windows?).returns true
        end
        let(:deprecation_message) { "Copying owner/mode/group from the" <<
              " source file on Windows is deprecated;" <<
              " use source_permissions => ignore." }

        it "should copy only mode from remote sources" do
          @source.stubs(:local?).returns false

          @source.copy_source_values

          @resource[:owner].must be_nil
          @resource[:group].must be_nil
          @resource[:mode].must == "173"
        end

        it "should copy mode from remote sources" do
          @source.stubs(:local?).returns false

          @source.copy_source_values

          @resource[:mode].must == "173"
        end

        it "should copy owner and group from local sources" do
          @source.stubs(:local?).returns true

          @source.copy_source_values

          @resource[:owner].must == 100
          @resource[:group].must == 200
          @resource[:mode].must == "173"
        end

        it "should issue deprecation warning when copying metadata from remote sources when group, owner, and mode are unspecified" do
          @source.stubs(:local?).returns false
          Puppet.expects(:deprecation_warning).with(deprecation_message).at_least_once

          @source.copy_source_values
        end

        it "should issue deprecation warning when copying metadata from remote sources if only user is unspecified" do
          @source.stubs(:local?).returns false
          Puppet.expects(:deprecation_warning).with(deprecation_message).at_least_once
          @resource[:group] = 2
          @resource[:mode] = 3

          @source.copy_source_values
        end

        it "should issue deprecation warning when copying metadata from remote sources if only group is unspecified" do
          @source.stubs(:local?).returns false
          Puppet.expects(:deprecation_warning).with(deprecation_message).at_least_once
          @resource[:owner] = 1
          @resource[:mode] = 3

          @source.copy_source_values
        end

        it "should issue deprecation warning when copying metadata from remote sources if only mode is unspecified" do
          @source.stubs(:local?).returns false
          Puppet.expects(:deprecation_warning).with(deprecation_message).at_least_once
          @resource[:owner] = 1
          @resource[:group] = 2

          @source.copy_source_values
        end

        it "should not issue deprecation warning when copying metadata from remote sources if group, owner, and mode are all specified" do
          @source.stubs(:local?).returns false
          Puppet.expects(:deprecation_warning).with(deprecation_message).never
          @resource[:owner] = 1
          @resource[:group] = 2
          @resource[:mode] = 3

          @source.copy_source_values
        end
      end
    end

    describe "and the source is a link" do
      it "should set the target to the link destination" do
        @metadata.stubs(:ftype).returns "link"
        @metadata.stubs(:links).returns "manage"
        @resource.stubs(:[])
        @resource.stubs(:[]=)

        @metadata.expects(:destination).returns "/path/to/symlink"

        @resource.expects(:[]=).with(:target, "/path/to/symlink")
        @source.copy_source_values
      end
    end
  end

  it "should have a local? method" do
    source.new(:resource => @resource).must be_respond_to(:local?)
  end

  context "when accessing source properties" do
    let(:catalog) { Puppet::Resource::Catalog.new }
    let(:path) { tmpfile('file_resource') }
    let(:resource) { Puppet::Type.type(:file).new(:path => path, :catalog => catalog) }
    let(:sourcepath) { tmpfile('file_source') }

    describe "for local sources" do
      before :each do
        FileUtils.touch(sourcepath)
      end

      describe "on POSIX systems", :if => Puppet.features.posix? do
        ['', "file:", "file://"].each do |prefix|
          it "with prefix '#{prefix}' should be local" do
            resource[:source] = "#{prefix}#{sourcepath}"
            resource.parameter(:source).must be_local
          end

          it "should be able to return the metadata source full path" do
            resource[:source] = "#{prefix}#{sourcepath}"
            resource.parameter(:source).full_path.should == sourcepath
          end
        end
      end

      describe "on Windows systems", :if => Puppet.features.microsoft_windows? do
        ['', "file:/", "file:///"].each do |prefix|
          it "should be local with prefix '#{prefix}'" do
            resource[:source] = "#{prefix}#{sourcepath}"
            resource.parameter(:source).must be_local
          end

          it "should be able to return the metadata source full path" do
            resource[:source] = "#{prefix}#{sourcepath}"
            resource.parameter(:source).full_path.should == sourcepath
          end

          it "should convert backslashes to forward slashes" do
            resource[:source] = "#{prefix}#{sourcepath.gsub(/\\/, '/')}"
          end
        end

        it "should be UNC with two slashes"
      end
    end

    describe "for remote sources" do
      let(:sourcepath) { "/path/to/source" }
      let(:uri) { URI::Generic.build(:scheme => 'puppet', :host => 'server', :port => 8192, :path => sourcepath).to_s }

      before(:each) do
        metadata = Puppet::FileServing::Metadata.new(path, :source => uri, 'type' => 'file')
        #metadata = stub('remote', :ftype => "file", :source => uri)
        Puppet::FileServing::Metadata.indirection.stubs(:find).
          with(uri,all_of(has_key(:environment), has_key(:links))).returns metadata
        resource[:source] = uri
      end

      it "should not be local" do
        resource.parameter(:source).should_not be_local
      end

      it "should be able to return the metadata source full path" do
        resource.parameter(:source).full_path.should == "/path/to/source"
      end

      it "should be able to return the source server" do
        resource.parameter(:source).server.should == "server"
      end

      it "should be able to return the source port" do
        resource.parameter(:source).port.should == 8192
      end

      describe "which don't specify server or port" do
        let(:uri) { "puppet:///path/to/source" }

        it "should return the default source server" do
          Puppet[:server] = "myserver"
          resource.parameter(:source).server.should == "myserver"
        end

        it "should return the default source port" do
          Puppet[:masterport] = 1234
          resource.parameter(:source).port.should == 1234
        end
      end
    end
  end
end
