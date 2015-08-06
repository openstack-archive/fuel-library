#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/application'
require 'puppet'
require 'getoptlong'
require 'timeout'

describe Puppet::Application do

  before(:each) do
    Puppet::Util::Instrumentation.stubs(:init)
    @app = Class.new(Puppet::Application).new
    @appclass = @app.class

    @app.stubs(:name).returns("test_app")

  end

  describe "application commandline" do
    it "should not pick up changes to the array of arguments" do
      args = %w{subcommand --arg}
      command_line = Puppet::Util::CommandLine.new('puppet', args)
      app = Puppet::Application.new(command_line)

      args[0] = 'different_subcommand'
      args[1] = '--other-arg'

      app.command_line.subcommand_name.should == 'subcommand'
      app.command_line.args.should == ['--arg']
    end
  end

  describe "application defaults" do
    it "should fail if required app default values are missing" do
      @app.stubs(:app_defaults).returns({ :foo => 'bar' })
      Puppet.expects(:err).with(regexp_matches(/missing required app default setting/))
      expect {
        @app.run
      }.to exit_with 1
    end
  end

  describe "finding" do
    before do
      @klass = Puppet::Application
      @klass.stubs(:puts)
    end

    it "should find classes in the namespace" do
      @klass.find("Agent").should == @klass::Agent
    end

    it "should not find classes outside the namespace" do
      expect { @klass.find("String") }.to raise_error(LoadError)
    end

    it "should error if it can't find a class" do
      Puppet.expects(:err).with do |value|
        value =~ /Unable to find application 'ThisShallNeverEverEverExist'/ and
          value =~ /puppet\/application\/thisshallneverevereverexist/ and
          value =~ /no such file to load|cannot load such file/
      end

      expect {
        @klass.find("ThisShallNeverEverEverExist")
      }.to raise_error(LoadError)
    end

    it "#12114: should prevent File namespace collisions" do
      # have to require the file face once, then the second time around it would fail
      @klass.find("File").should == Puppet::Application::File
      @klass.find("File").should == Puppet::Application::File
    end
  end

  describe "#available_application_names" do
    it 'should be able to find available application names' do
      apps =  %w{describe filebucket kick queue resource agent cert apply doc master}
      Puppet::Util::Autoload.expects(:files_to_load).returns(apps)

      Puppet::Application.available_application_names.should =~ apps
    end

    it 'should find applications from multiple paths' do
      Puppet::Util::Autoload.expects(:files_to_load).with('puppet/application').returns(%w{ /a/foo.rb /b/bar.rb })

      Puppet::Application.available_application_names.should =~ %w{ foo bar }
    end

    it 'should return unique application names' do
      Puppet::Util::Autoload.expects(:files_to_load).with('puppet/application').returns(%w{ /a/foo.rb /b/foo.rb })

      Puppet::Application.available_application_names.should == %w{ foo }
    end
  end

  describe ".run_mode" do
    it "should default to user" do
      @appclass.run_mode.name.should == :user
    end

    it "should set and get a value" do
      @appclass.run_mode :agent
      @appclass.run_mode.name.should == :agent
    end
  end



  # These tests may look a little weird and repetative in its current state;
  #  it used to illustrate several ways that the run_mode could be changed
  #  at run time; there are fewer ways now, but it would still be nice to
  #  get to a point where it was entirely impossible.
  describe "when dealing with run_mode" do

    class TestApp < Puppet::Application
      run_mode :master
      def run_command
        # no-op
      end
    end

    it "should sadly and frighteningly allow run_mode to change at runtime via #initialize_app_defaults" do
      Puppet.features.stubs(:syslog?).returns(true)

      app = TestApp.new
      app.initialize_app_defaults

      Puppet.run_mode.should be_master
    end

    it "should sadly and frighteningly allow run_mode to change at runtime via #run" do
      app = TestApp.new
      app.run

      app.class.run_mode.name.should == :master

      Puppet.run_mode.should be_master
    end
  end

  it "should explode when an invalid run mode is set at runtime, for great victory" do
    expect {
      class InvalidRunModeTestApp < Puppet::Application
        run_mode :abracadabra
        def run_command
          # no-op
        end
      end
    }.to raise_error
  end

  it "should have a run entry-point" do
    @app.should respond_to(:run)
  end

  it "should have a read accessor to options" do
    @app.should respond_to(:options)
  end

  it "should include a default setup method" do
    @app.should respond_to(:setup)
  end

  it "should include a default preinit method" do
    @app.should respond_to(:preinit)
  end

  it "should include a default run_command method" do
    @app.should respond_to(:run_command)
  end

  it "should invoke main as the default" do
    @app.expects( :main )
    @app.run_command
  end

  it "should initialize the Puppet Instrumentation layer early in the life cycle" do
    # Not proud of this, but the fact that we are stubbing init_app_defaults
    #  below means that we will get errors if anyone tries to access any
    #  settings that depend on app_defaults.  In general this whole test
    #  seems to be testing too many implementation details rather than
    #  functionality, but, hey.
    Puppet[:route_file] = "/dev/null"

    startup_sequence = sequence('startup')
    @app.expects(:initialize_app_defaults).in_sequence(startup_sequence)
    Puppet::Util::Instrumentation.expects(:init).in_sequence(startup_sequence)
    @app.expects(:preinit).in_sequence(startup_sequence)

    expect { @app.run }.to exit_with(1)
  end

  describe 'when invoking clear!' do
    before :each do
      Puppet::Application.run_status = :stop_requested
      Puppet::Application.clear!
    end

    it 'should have nil run_status' do
      Puppet::Application.run_status.should be_nil
    end

    it 'should return false for restart_requested?' do
      Puppet::Application.restart_requested?.should be_false
    end

    it 'should return false for stop_requested?' do
      Puppet::Application.stop_requested?.should be_false
    end

    it 'should return false for interrupted?' do
      Puppet::Application.interrupted?.should be_false
    end

    it 'should return true for clear?' do
      Puppet::Application.clear?.should be_true
    end
  end

  describe 'after invoking stop!' do
    before :each do
      Puppet::Application.run_status = nil
      Puppet::Application.stop!
    end

    after :each do
      Puppet::Application.run_status = nil
    end

    it 'should have run_status of :stop_requested' do
      Puppet::Application.run_status.should == :stop_requested
    end

    it 'should return true for stop_requested?' do
      Puppet::Application.stop_requested?.should be_true
    end

    it 'should return false for restart_requested?' do
      Puppet::Application.restart_requested?.should be_false
    end

    it 'should return true for interrupted?' do
      Puppet::Application.interrupted?.should be_true
    end

    it 'should return false for clear?' do
      Puppet::Application.clear?.should be_false
    end
  end

  describe 'when invoking restart!' do
    before :each do
      Puppet::Application.run_status = nil
      Puppet::Application.restart!
    end

    after :each do
      Puppet::Application.run_status = nil
    end

    it 'should have run_status of :restart_requested' do
      Puppet::Application.run_status.should == :restart_requested
    end

    it 'should return true for restart_requested?' do
      Puppet::Application.restart_requested?.should be_true
    end

    it 'should return false for stop_requested?' do
      Puppet::Application.stop_requested?.should be_false
    end

    it 'should return true for interrupted?' do
      Puppet::Application.interrupted?.should be_true
    end

    it 'should return false for clear?' do
      Puppet::Application.clear?.should be_false
    end
  end

  describe 'when performing a controlled_run' do
    it 'should not execute block if not :clear?' do
      Puppet::Application.run_status = :stop_requested
      target = mock 'target'
      target.expects(:some_method).never
      Puppet::Application.controlled_run do
        target.some_method
      end
    end

    it 'should execute block if :clear?' do
      Puppet::Application.run_status = nil
      target = mock 'target'
      target.expects(:some_method).once
      Puppet::Application.controlled_run do
        target.some_method
      end
    end

    describe 'on POSIX systems', :if => Puppet.features.posix? do
      it 'should signal process with HUP after block if restart requested during block execution' do
        Timeout::timeout(3) do  # if the signal doesn't fire, this causes failure.

          has_run = false
          old_handler = trap('HUP') { has_run = true }

          begin
            Puppet::Application.controlled_run do
              Puppet::Application.run_status = :restart_requested
            end

            # Ruby 1.9 uses a separate OS level thread to run the signal
            # handler, so we have to poll - ideally, in a way that will kick
            # the OS into running other threads - for a while.
            #
            # You can't just use the Ruby Thread yield thing either, because
            # that is just an OS hint, and Linux ... doesn't take that
            # seriously. --daniel 2012-03-22
            sleep 0.001 while not has_run
          ensure
            trap('HUP', old_handler)
          end
        end
      end
    end

    after :each do
      Puppet::Application.run_status = nil
    end
  end

  describe "when parsing command-line options" do

    before :each do
      @app.command_line.stubs(:args).returns([])

      Puppet.settings.stubs(:optparse_addargs).returns([])
    end

    it "should pass the banner to the option parser" do
      option_parser = stub "option parser"
      option_parser.stubs(:on)
      option_parser.stubs(:parse!)
      @app.class.instance_eval do
        banner "banner"
      end

      OptionParser.expects(:new).with("banner").returns(option_parser)

      @app.parse_options
    end

    it "should ask OptionParser to parse the command-line argument" do
      @app.command_line.stubs(:args).returns(%w{ fake args })
      OptionParser.any_instance.expects(:parse!).with(%w{ fake args })

      @app.parse_options
    end

    describe "when using --help" do

      it "should call exit" do
        @app.stubs(:puts)
        expect { @app.handle_help(nil) }.to exit_with 0
      end

    end

    describe "when using --version" do
      it "should declare a version option" do
        @app.should respond_to(:handle_version)
      end

      it "should exit after printing the version" do
        @app.stubs(:puts)
        expect { @app.handle_version(nil) }.to exit_with 0
      end
    end

    describe "when dealing with an argument not declared directly by the application" do
      it "should pass it to handle_unknown if this method exists" do
        Puppet.settings.stubs(:optparse_addargs).returns([["--not-handled", :REQUIRED]])

        @app.expects(:handle_unknown).with("--not-handled", "value").returns(true)
        @app.command_line.stubs(:args).returns(["--not-handled", "value"])
        @app.parse_options
      end

      it "should transform boolean option to normal form for Puppet.settings" do
        @app.expects(:handle_unknown).with("--option", true)
        @app.send(:handlearg, "--[no-]option", true)
      end

      it "should transform boolean option to no- form for Puppet.settings" do
        @app.expects(:handle_unknown).with("--no-option", false)
        @app.send(:handlearg, "--[no-]option", false)
      end

    end
  end

  describe "when calling default setup" do

    before :each do
      @app.options.stubs(:[])
    end

    [ :debug, :verbose ].each do |level|
      it "should honor option #{level}" do
        @app.options.stubs(:[]).with(level).returns(true)
        Puppet::Util::Log.stubs(:newdestination)
        @app.setup
        Puppet::Util::Log.level.should == (level == :verbose ? :info : :debug)
      end
    end

    it "should honor setdest option" do
      @app.options.stubs(:[]).with(:setdest).returns(false)

      Puppet::Util::Log.expects(:setup_default)

      @app.setup
    end

  end

  describe "when configuring routes" do
    include PuppetSpec::Files

    before :each do
      Puppet::Node.indirection.reset_terminus_class
    end

    after :each do
      Puppet::Node.indirection.reset_terminus_class
    end

    it "should use the routes specified for only the active application" do
      Puppet[:route_file] = tmpfile('routes')
      File.open(Puppet[:route_file], 'w') do |f|
        f.print <<-ROUTES
          test_app:
            node:
              terminus: exec
          other_app:
            node:
              terminus: plain
            catalog:
              terminus: invalid
        ROUTES
      end

      @app.configure_indirector_routes

      Puppet::Node.indirection.terminus_class.should == 'exec'
    end

    it "should not fail if the route file doesn't exist" do
      Puppet[:route_file] = "/dev/null/non-existent"

      expect { @app.configure_indirector_routes }.to_not raise_error
    end

    it "should raise an error if the routes file is invalid" do
      Puppet[:route_file] = tmpfile('routes')
      File.open(Puppet[:route_file], 'w') do |f|
        f.print <<-ROUTES
         invalid : : yaml
        ROUTES
      end

      expect { @app.configure_indirector_routes }.to raise_error
    end
  end

  describe "when running" do

    before :each do
      @app.stubs(:preinit)
      @app.stubs(:setup)
      @app.stubs(:parse_options)
    end

    it "should call preinit" do
      @app.stubs(:run_command)

      @app.expects(:preinit)

      @app.run
    end

    it "should call parse_options" do
      @app.stubs(:run_command)

      @app.expects(:parse_options)

      @app.run
    end

    it "should call run_command" do

      @app.expects(:run_command)

      @app.run
    end


    it "should call run_command" do
      @app.expects(:run_command)

      @app.run
    end

    it "should call main as the default command" do
      @app.expects(:main)

      @app.run
    end

    it "should warn and exit if no command can be called" do
      Puppet.expects(:err)
      expect { @app.run }.to exit_with 1
    end

    it "should raise an error if dispatch returns no command" do
      @app.stubs(:get_command).returns(nil)
      Puppet.expects(:err)
      expect { @app.run }.to exit_with 1
    end

    it "should raise an error if dispatch returns an invalid command" do
      @app.stubs(:get_command).returns(:this_function_doesnt_exist)
      Puppet.expects(:err)
      expect { @app.run }.to exit_with 1
    end
  end

  describe "when metaprogramming" do

    describe "when calling option" do
      it "should create a new method named after the option" do
        @app.class.option("--test1","-t") do
        end

        @app.should respond_to(:handle_test1)
      end

      it "should transpose in option name any '-' into '_'" do
        @app.class.option("--test-dashes-again","-t") do
        end

        @app.should respond_to(:handle_test_dashes_again)
      end

      it "should create a new method called handle_test2 with option(\"--[no-]test2\")" do
        @app.class.option("--[no-]test2","-t") do
        end

        @app.should respond_to(:handle_test2)
      end

      describe "when a block is passed" do
        it "should create a new method with it" do
          @app.class.option("--[no-]test2","-t") do
            raise "I can't believe it, it works!"
          end

          expect { @app.handle_test2 }.to raise_error
        end

        it "should declare the option to OptionParser" do
          OptionParser.any_instance.stubs(:on)
          OptionParser.any_instance.expects(:on).with { |*arg| arg[0] == "--[no-]test3" }

          @app.class.option("--[no-]test3","-t") do
          end

          @app.parse_options
        end

        it "should pass a block that calls our defined method" do
          OptionParser.any_instance.stubs(:on)
          OptionParser.any_instance.stubs(:on).with('--test4','-t').yields(nil)

          @app.expects(:send).with(:handle_test4, nil)

          @app.class.option("--test4","-t") do
          end

          @app.parse_options
        end
      end

      describe "when no block is given" do
        it "should declare the option to OptionParser" do
          OptionParser.any_instance.stubs(:on)
          OptionParser.any_instance.expects(:on).with("--test4","-t")

          @app.class.option("--test4","-t")

          @app.parse_options
        end

        it "should give to OptionParser a block that adds the the value to the options array" do
          OptionParser.any_instance.stubs(:on)
          OptionParser.any_instance.stubs(:on).with("--test4","-t").yields(nil)

          @app.options.expects(:[]=).with(:test4,nil)

          @app.class.option("--test4","-t")

          @app.parse_options
        end
      end
    end

  end

  describe "#handle_logdest_arg" do

    let(:test_arg) { "arg_test_logdest" }

    it "should log an exception that is raised" do
      our_exception = Puppet::DevError.new("test exception")
      Puppet::Util::Log.expects(:newdestination).with(test_arg).raises(our_exception)
      Puppet.expects(:log_exception).with(our_exception)
      @app.handle_logdest_arg(test_arg)
    end

    it "should set the new log destination" do
      Puppet::Util::Log.expects(:newdestination).with(test_arg)
      @app.handle_logdest_arg(test_arg)
    end

    it "should set the flag that a destination is set in the options hash" do
      Puppet::Util::Log.stubs(:newdestination).with(test_arg)
      @app.handle_logdest_arg(test_arg)
      @app.options[:setdest].should be_true
    end
  end

end
