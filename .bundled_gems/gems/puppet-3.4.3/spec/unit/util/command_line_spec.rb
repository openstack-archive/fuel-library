#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/face'
require 'puppet/util/command_line'

describe Puppet::Util::CommandLine do
  include PuppetSpec::Files

  context "#initialize" do
    it "should pull off the first argument if it looks like a subcommand" do
      command_line = Puppet::Util::CommandLine.new("puppet", %w{ client --help whatever.pp })

      command_line.subcommand_name.should == "client"
      command_line.args.should            == %w{ --help whatever.pp }
    end

    it "should return nil if the first argument looks like a .pp file" do
      command_line = Puppet::Util::CommandLine.new("puppet", %w{ whatever.pp })

      command_line.subcommand_name.should == nil
      command_line.args.should            == %w{ whatever.pp }
    end

    it "should return nil if the first argument looks like a .rb file" do
      command_line = Puppet::Util::CommandLine.new("puppet", %w{ whatever.rb })

      command_line.subcommand_name.should == nil
      command_line.args.should            == %w{ whatever.rb }
    end

    it "should return nil if the first argument looks like a flag" do
      command_line = Puppet::Util::CommandLine.new("puppet", %w{ --debug })

      command_line.subcommand_name.should == nil
      command_line.args.should            == %w{ --debug }
    end

    it "should return nil if the first argument is -" do
      command_line = Puppet::Util::CommandLine.new("puppet", %w{ - })

      command_line.subcommand_name.should == nil
      command_line.args.should            == %w{ - }
    end

    it "should return nil if the first argument is --help" do
      command_line = Puppet::Util::CommandLine.new("puppet", %w{ --help })

      command_line.subcommand_name.should == nil
    end


    it "should return nil if there are no arguments" do
      command_line = Puppet::Util::CommandLine.new("puppet", [])

      command_line.subcommand_name.should == nil
      command_line.args.should            == []
    end

    it "should pick up changes to the array of arguments" do
      args = %w{subcommand}
      command_line = Puppet::Util::CommandLine.new("puppet", args)
      args[0] = 'different_subcommand'
      command_line.subcommand_name.should == 'different_subcommand'
    end
  end

  context "#execute" do
    %w{--version -V}.each do |arg|
      it "should print the version and exit if #{arg} is given" do
        expect do
          described_class.new("puppet", [arg]).execute
        end.to have_printed(/^#{Puppet.version}$/)
      end
    end
  end

  describe "when dealing with puppet commands" do
    it "should return the executable name if it is not puppet" do
      command_line = Puppet::Util::CommandLine.new("puppetmasterd", [])
      command_line.subcommand_name.should == "puppetmasterd"
    end

    describe "when the subcommand is not implemented" do
      it "should find and invoke an executable with a hyphenated name" do
        commandline = Puppet::Util::CommandLine.new("puppet", ['whatever', 'argument'])
        Puppet::Util.expects(:which).with('puppet-whatever').
          returns('/dev/null/puppet-whatever')

        Kernel.expects(:exec).with('/dev/null/puppet-whatever', 'argument')

        commandline.execute
      end

      describe "and an external implementation cannot be found" do
        it "should abort and show the usage message" do
          commandline = Puppet::Util::CommandLine.new("puppet", ['whatever', 'argument'])
          Puppet::Util.expects(:which).with('puppet-whatever').returns(nil)
          commandline.expects(:exec).never

          expect {
            commandline.execute
          }.to have_printed(/Unknown Puppet subcommand 'whatever'/)
        end

        it "should abort and show the help message" do
          commandline = Puppet::Util::CommandLine.new("puppet", ['whatever', 'argument'])
          Puppet::Util.expects(:which).with('puppet-whatever').returns(nil)
          commandline.expects(:exec).never

          expect {
            commandline.execute
          }.to have_printed(/See 'puppet help' for help on available puppet subcommands/)
        end

        %w{--version -V}.each do |arg|
          it "should abort and display #{arg} information" do
            commandline = Puppet::Util::CommandLine.new("puppet", ['whatever', arg])
            Puppet::Util.expects(:which).with('puppet-whatever').returns(nil)
            commandline.expects(:exec).never

            expect {
              commandline.execute
            }.to have_printed(/^#{Puppet.version}$/)
          end
        end
      end
    end

    describe 'when loading commands' do
      it "should deprecate the available_subcommands instance method" do
        Puppet::Application.expects(:available_application_names)
        Puppet.expects(:deprecation_warning).with("Puppet::Util::CommandLine#available_subcommands is deprecated; please use Puppet::Application.available_application_names instead.")

        command_line = Puppet::Util::CommandLine.new("foo", %w{ client --help whatever.pp })
        command_line.available_subcommands
      end

      it "should deprecate the available_subcommands class method" do
        Puppet::Application.expects(:available_application_names)
        Puppet.expects(:deprecation_warning).with("Puppet::Util::CommandLine.available_subcommands is deprecated; please use Puppet::Application.available_application_names instead.")

        Puppet::Util::CommandLine.available_subcommands
      end
    end

    describe 'when setting process priority' do
      let(:command_line) do
        Puppet::Util::CommandLine.new("puppet", %w{ agent })
      end

      before :each do
        Puppet::Util::CommandLine::ApplicationSubcommand.any_instance.stubs(:run)
      end

      it 'should never set priority by default' do
        Process.expects(:setpriority).never

        command_line.execute
      end

      it 'should lower the process priority if one has been specified' do
        Puppet[:priority] = 10

        Process.expects(:setpriority).with(0, Process.pid, 10)
        command_line.execute
      end

      it 'should warn if trying to raise priority, but not privileged user' do
        Puppet[:priority] = -10

        Process.expects(:setpriority).raises(Errno::EACCES, 'Permission denied')
        Puppet.expects(:warning).with("Failed to set process priority to '-10'")

        command_line.execute
      end

      it "should warn if the platform doesn't support `Process.setpriority`" do
        Puppet[:priority] = 15

        Process.expects(:setpriority).raises(NotImplementedError, 'NotImplementedError: setpriority() function is unimplemented on this machine')
        Puppet.expects(:warning).with("Failed to set process priority to '15'")

        command_line.execute
      end
    end
  end
end
