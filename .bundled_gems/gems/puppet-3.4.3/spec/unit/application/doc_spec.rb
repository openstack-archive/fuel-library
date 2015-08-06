#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/application/doc'
require 'puppet/util/reference'
require 'puppet/util/rdoc'

describe Puppet::Application::Doc do
  before :each do
    @doc = Puppet::Application[:doc]
    @doc.stubs(:puts)
    @doc.preinit
    Puppet::Util::Log.stubs(:newdestination)
  end

  it "should declare an other command" do
    @doc.should respond_to(:other)
  end

  it "should declare a rdoc command" do
    @doc.should respond_to(:rdoc)
  end

  it "should declare a fallback for unknown options" do
    @doc.should respond_to(:handle_unknown)
  end

  it "should declare a preinit block" do
    @doc.should respond_to(:preinit)
  end

  describe "in preinit" do
    it "should set references to []" do
      @doc.preinit

      @doc.options[:references].should == []
    end

    it "should init mode to text" do
      @doc.preinit

      @doc.options[:mode].should == :text
    end

    it "should init format to to_markdown" do
      @doc.preinit

      @doc.options[:format].should == :to_markdown
    end
  end

  describe "when handling options" do
    [:all, :outputdir, :verbose, :debug, :charset].each do |option|
      it "should declare handle_#{option} method" do
        @doc.should respond_to("handle_#{option}".to_sym)
      end

      it "should store argument value when calling handle_#{option}" do
        @doc.options.expects(:[]=).with(option, 'arg')
        @doc.send("handle_#{option}".to_sym, 'arg')
      end
    end

    it "should store the format if valid" do
      Puppet::Util::Reference.stubs(:method_defined?).with('to_format').returns(true)

      @doc.handle_format('format')
      @doc.options[:format].should == 'to_format'
    end

    it "should raise an error if the format is not valid" do
      Puppet::Util::Reference.stubs(:method_defined?).with('to_format').returns(false)
      expect { @doc.handle_format('format') }.to raise_error(RuntimeError, /Invalid output format/)
    end

    it "should store the mode if valid" do
      Puppet::Util::Reference.stubs(:modes).returns(stub('mode', :include? => true))

      @doc.handle_mode('mode')
      @doc.options[:mode].should == :mode
    end

    it "should store the mode if :rdoc" do
      Puppet::Util::Reference.modes.stubs(:include?).with('rdoc').returns(false)

      @doc.handle_mode('rdoc')
      @doc.options[:mode].should == :rdoc
    end

    it "should raise an error if the mode is not valid" do
      Puppet::Util::Reference.modes.stubs(:include?).with('unknown').returns(false)
      expect { @doc.handle_mode('unknown') }.to raise_error(RuntimeError, /Invalid output mode/)
    end

    it "should list all references on list and exit" do
      reference = stubs 'reference'
      ref = stubs 'ref'
      Puppet::Util::Reference.stubs(:references).returns([reference])

      Puppet::Util::Reference.expects(:reference).with(reference).returns(ref)
      ref.expects(:doc)

      expect { @doc.handle_list(nil) }.to exit_with 0
    end

    it "should add reference to references list with --reference" do
      @doc.options[:references] = [:ref1]

      @doc.handle_reference('ref2')

      @doc.options[:references].should == [:ref1,:ref2]
    end
  end

  describe "during setup" do

    before :each do
      Puppet::Log.stubs(:newdestination)
      @doc.command_line.stubs(:args).returns([])
    end

    it "should default to rdoc mode if there are command line arguments" do
      @doc.command_line.stubs(:args).returns(["1"])
      @doc.stubs(:setup_rdoc)

      @doc.setup
      @doc.options[:mode].should == :rdoc
    end

    it "should call setup_rdoc in rdoc mode" do
      @doc.options[:mode] = :rdoc

      @doc.expects(:setup_rdoc)

      @doc.setup
    end

    it "should call setup_reference if not rdoc" do
      @doc.options[:mode] = :test

      @doc.expects(:setup_reference)

      @doc.setup
    end

    describe "configuring logging" do
      before :each do
        Puppet::Util::Log.stubs(:newdestination)
      end

      describe "with --debug" do
        before do
          @doc.options[:debug] = true
        end

        it "should set log level to debug" do
          @doc.setup
          Puppet::Util::Log.level.should == :debug
        end

        it "should set log destination to console" do
          Puppet::Util::Log.expects(:newdestination).with(:console)
          @doc.setup
        end
      end

      describe "with --verbose" do
        before do
          @doc.options[:verbose] = true
        end

        it "should set log level to info" do
          @doc.setup
          Puppet::Util::Log.level.should == :info
        end

        it "should set log destination to console" do
          Puppet::Util::Log.expects(:newdestination).with(:console)
          @doc.setup
        end
      end

      describe "without --debug or --verbose" do
        before do
          @doc.options[:debug] = false
          @doc.options[:verbose] = false
        end

        it "should set log level to warning" do
          @doc.setup
          Puppet::Util::Log.level.should == :warning
        end

        it "should set log destination to console" do
          Puppet::Util::Log.expects(:newdestination).with(:console)
          @doc.setup
        end
      end
    end

    describe "in non-rdoc mode" do
      it "should get all non-dynamic reference if --all" do
        @doc.options[:all] = true
        static = stub 'static', :dynamic? => false
        dynamic = stub 'dynamic', :dynamic? => true
        Puppet::Util::Reference.stubs(:reference).with(:static).returns(static)
        Puppet::Util::Reference.stubs(:reference).with(:dynamic).returns(dynamic)
        Puppet::Util::Reference.stubs(:references).returns([:static,:dynamic])

        @doc.setup_reference
        @doc.options[:references].should == [:static]
      end

      it "should default to :type if no references" do
        @doc.setup_reference
        @doc.options[:references].should == [:type]
      end
    end

    describe "in rdoc mode" do
      describe "when there are unknown args" do
        it "should expand --modulepath if any" do
          @doc.unknown_args = [ { :opt => "--modulepath", :arg => "path" } ]
          Puppet.settings.stubs(:handlearg)

          File.expects(:expand_path).with("path")

          @doc.setup_rdoc
        end

        it "should expand --manifestdir if any" do
          @doc.unknown_args = [ { :opt => "--manifestdir", :arg => "path" } ]
          Puppet.settings.stubs(:handlearg)

          File.expects(:expand_path).with("path")

          @doc.setup_rdoc
        end

        it "should give them to Puppet.settings" do
          @doc.unknown_args = [ { :opt => :option, :arg => :argument } ]
          Puppet.settings.expects(:handlearg).with(:option,:argument)

          @doc.setup_rdoc
        end
      end

      it "should operate in master run_mode" do
        @doc.class.run_mode.name.should == :master

        @doc.setup_rdoc
      end
    end
  end

  describe "when running" do
    describe "in rdoc mode" do
      let(:modules) { File.expand_path("modules") }
      let(:manifests) { File.expand_path("manifests") }

      before :each do
        @doc.manifest = false
        Puppet.stubs(:info)
        Puppet[:trace] = false
        @env = stub 'env'
        @env.stubs(:modulepath).returns([modules])
        @env.stubs(:[]).with(:manifest).returns('manifests/site.pp')
        Puppet::Node::Environment.stubs(:new).returns(@env)
        Puppet[:modulepath] = modules
        Puppet[:manifestdir] = manifests
        @doc.options[:all] = false
        @doc.options[:outputdir] = 'doc'
        @doc.options[:charset] = nil
        Puppet.settings.stubs(:define_settings)
        Puppet::Util::RDoc.stubs(:rdoc)
        @doc.command_line.stubs(:args).returns([])
      end

      it "should set document_all on --all" do
        @doc.options[:all] = true
        Puppet.settings.expects(:[]=).with(:document_all, true)

        expect { @doc.rdoc }.to exit_with 0
      end

      it "should call Puppet::Util::RDoc.rdoc in full mode" do
        Puppet::Util::RDoc.expects(:rdoc).with('doc', [modules, 'manifests'], nil)
        expect { @doc.rdoc }.to exit_with 0
      end

      it "should call Puppet::Util::RDoc.rdoc with a charset if --charset has been provided" do
        @doc.options[:charset] = 'utf-8'
        Puppet::Util::RDoc.expects(:rdoc).with('doc', [modules, 'manifests'], "utf-8")
        expect { @doc.rdoc }.to exit_with 0
      end

      it "should call Puppet::Util::RDoc.rdoc in full mode with outputdir set to doc if no --outputdir" do
        @doc.options[:outputdir] = false
        Puppet::Util::RDoc.expects(:rdoc).with('doc', [modules, 'manifests'], nil)
        expect { @doc.rdoc }.to exit_with 0
      end

      it "should call Puppet::Util::RDoc.manifestdoc in manifest mode" do
        @doc.manifest = true
        Puppet::Util::RDoc.expects(:manifestdoc)
        expect { @doc.rdoc }.to exit_with 0
      end

      it "should get modulepath and manifestdir values from the environment" do
        @env.expects(:modulepath).returns(['envmodules1','envmodules2'])
        @env.expects(:[]).with(:manifest).returns('envmanifests/site.pp')

        Puppet::Util::RDoc.expects(:rdoc).with('doc', ['envmodules1','envmodules2','envmanifests'], nil)

        expect { @doc.rdoc }.to exit_with 0
      end
    end

    describe "in the other modes" do
      it "should get reference in given format" do
        reference = stub 'reference'
        @doc.options[:mode] = :none
        @doc.options[:references] = [:ref]
        Puppet::Util::Reference.expects(:reference).with(:ref).returns(reference)
        @doc.options[:format] = :format
        @doc.stubs(:exit)

        reference.expects(:send).with { |format,contents| format == :format }.returns('doc')
        @doc.other
      end
    end
  end
end
