#! /usr/bin/env ruby
require 'spec_helper'
require 'ostruct'
require 'puppet/settings/errors'

describe Puppet::Settings do
  include PuppetSpec::Files

  let(:main_config_file_default_location) do
    File.join(Puppet::Util::RunMode[:master].conf_dir, "puppet.conf")
  end

  let(:user_config_file_default_location) do
    File.join(Puppet::Util::RunMode[:user].conf_dir, "puppet.conf")
  end

  describe "when specifying defaults" do
    before do
      @settings = Puppet::Settings.new
    end

    it "should start with no defined parameters" do
      @settings.params.length.should == 0
    end

    it "should not allow specification of default values associated with a section as an array" do
      expect {
        @settings.define_settings(:section, :myvalue => ["defaultval", "my description"])
      }.to raise_error
    end

    it "should not allow duplicate parameter specifications" do
      @settings.define_settings(:section, :myvalue => { :default => "a", :desc => "b" })
      lambda { @settings.define_settings(:section, :myvalue => { :default => "c", :desc => "d" }) }.should raise_error(ArgumentError)
    end

    it "should allow specification of default values associated with a section as a hash" do
      @settings.define_settings(:section, :myvalue => {:default => "defaultval", :desc => "my description"})
    end

    it "should consider defined parameters to be valid" do
      @settings.define_settings(:section, :myvalue => { :default => "defaultval", :desc => "my description" })
      @settings.valid?(:myvalue).should be_true
    end

    it "should require a description when defaults are specified with a hash" do
      lambda { @settings.define_settings(:section, :myvalue => {:default => "a value"}) }.should raise_error(ArgumentError)
    end

    it "should support specifying owner, group, and mode when specifying files" do
      @settings.define_settings(:section, :myvalue => {:type => :file, :default => "/some/file", :owner => "service", :mode => "boo", :group => "service", :desc => "whatever"})
    end

    it "should support specifying a short name" do
      @settings.define_settings(:section, :myvalue => {:default => "w", :desc => "b", :short => "m"})
    end

    it "should support specifying the setting type" do
      @settings.define_settings(:section, :myvalue => {:default => "/w", :desc => "b", :type => :string})
      @settings.setting(:myvalue).should be_instance_of(Puppet::Settings::StringSetting)
    end

    it "should fail if an invalid setting type is specified" do
      lambda { @settings.define_settings(:section, :myvalue => {:default => "w", :desc => "b", :type => :foo}) }.should raise_error(ArgumentError)
    end

    it "should fail when short names conflict" do
      @settings.define_settings(:section, :myvalue => {:default => "w", :desc => "b", :short => "m"})
      lambda { @settings.define_settings(:section, :myvalue => {:default => "w", :desc => "b", :short => "m"}) }.should raise_error(ArgumentError)
    end
  end


  describe "when initializing application defaults do" do
    let(:default_values) do
      values = {}
      PuppetSpec::Settings::TEST_APP_DEFAULT_DEFINITIONS.keys.each do |key|
        values[key] = 'default value'
      end
      values
    end

    before do
      @settings = Puppet::Settings.new
      @settings.define_settings(:main, PuppetSpec::Settings::TEST_APP_DEFAULT_DEFINITIONS)
    end

    it "should fail if the app defaults hash is missing any required values" do
      incomplete_default_values = default_values.reject { |key, _| key == :confdir }
      expect {
        @settings.initialize_app_defaults(default_values.reject { |key, _| key == :confdir })
      }.to raise_error(Puppet::Settings::SettingsError)
    end

    # ultimately I'd like to stop treating "run_mode" as a normal setting, because it has so many special
    #  case behaviors / uses.  However, until that time... we need to make sure that our private run_mode=
    #  setter method gets properly called during app initialization.
    it "sets the preferred run mode when initializing the app defaults" do
      @settings.initialize_app_defaults(default_values.merge(:run_mode => :master))

      @settings.preferred_run_mode.should == :master
    end
  end

  describe "#call_hooks_deferred_to_application_initialization" do
    let (:good_default) { "yay" }
    let (:bad_default) { "$doesntexist" }
    before(:each) do
      @settings = Puppet::Settings.new
    end

    describe "when ignoring dependency interpolation errors" do
      let(:options) { {:ignore_interpolation_dependency_errors => true} }

      describe "if interpolation error" do
        it "should not raise an error" do
          hook_values = []
          @settings.define_settings(:section, :badhook => {:default => bad_default, :desc => "boo", :call_hook => :on_initialize_and_write, :hook => lambda { |v| hook_values << v  }})
          expect do
            @settings.send(:call_hooks_deferred_to_application_initialization, options)
          end.to_not raise_error
        end
      end
      describe "if no interpolation error" do
        it "should not raise an error" do
          hook_values = []
          @settings.define_settings(:section, :goodhook => {:default => good_default, :desc => "boo", :call_hook => :on_initialize_and_write, :hook => lambda { |v| hook_values << v  }})
          expect do
            @settings.send(:call_hooks_deferred_to_application_initialization, options)
          end.to_not raise_error
        end
      end
    end

    describe "when not ignoring dependency interpolation errors" do
      [ {}, {:ignore_interpolation_dependency_errors => false}].each do |options|
        describe "if interpolation error" do
          it "should raise an error" do
            hook_values = []
            @settings.define_settings(
              :section,
              :badhook => {
                :default => bad_default,
                :desc => "boo",
                :call_hook => :on_initialize_and_write,
                :hook => lambda { |v| hook_values << v }
              }
            )
            expect do
              @settings.send(:call_hooks_deferred_to_application_initialization, options)
            end.to raise_error Puppet::Settings::InterpolationError
          end
          it "should contain the setting name in error message" do
            hook_values = []
            @settings.define_settings(
              :section,
              :badhook => {
                :default => bad_default,
                :desc => "boo",
                :call_hook => :on_initialize_and_write,
                :hook => lambda { |v| hook_values << v }
              }
            )
            expect do
              @settings.send(:call_hooks_deferred_to_application_initialization, options)
            end.to raise_error Puppet::Settings::InterpolationError, /badhook/
          end
        end
        describe "if no interpolation error" do
          it "should not raise an error" do
            hook_values = []
            @settings.define_settings(
              :section,
              :goodhook => {
                :default => good_default,
                :desc => "boo",
                :call_hook => :on_initialize_and_write,
                :hook => lambda { |v| hook_values << v }
              }
            )
            expect do
              @settings.send(:call_hooks_deferred_to_application_initialization, options)
            end.to_not raise_error
          end
        end
      end
    end
  end

  describe "when setting values" do
    before do
      @settings = Puppet::Settings.new
      @settings.define_settings :main, :myval => { :default => "val", :desc => "desc" }
      @settings.define_settings :main, :bool => { :type => :boolean, :default => true, :desc => "desc" }
    end

    it "should provide a method for setting values from other objects" do
      @settings[:myval] = "something else"
      @settings[:myval].should == "something else"
    end

    it "should support a getopt-specific mechanism for setting values" do
      @settings.handlearg("--myval", "newval")
      @settings[:myval].should == "newval"
    end

    it "should support a getopt-specific mechanism for turning booleans off" do
      @settings[:bool] = true
      @settings.handlearg("--no-bool", "")
      @settings[:bool].should == false
    end

    it "should support a getopt-specific mechanism for turning booleans on" do
      # Turn it off first
      @settings[:bool] = false
      @settings.handlearg("--bool", "")
      @settings[:bool].should == true
    end

    it "should consider a cli setting with no argument to be a boolean" do
      # Turn it off first
      @settings[:bool] = false
      @settings.handlearg("--bool")
      @settings[:bool].should == true
    end

    it "should consider a cli setting with an empty string as an argument to be a boolean, if the setting itself is a boolean" do
      # Turn it off first
      @settings[:bool] = false
      @settings.handlearg("--bool", "")
      @settings[:bool].should == true
    end

    it "should consider a cli setting with an empty string as an argument to be an empty argument, if the setting itself is not a boolean" do
      @settings[:myval] = "bob"
      @settings.handlearg("--myval", "")
      @settings[:myval].should == ""
    end

    it "should consider a cli setting with a boolean as an argument to be a boolean" do
      # Turn it off first
      @settings[:bool] = false
      @settings.handlearg("--bool", "true")
      @settings[:bool].should == true
    end

    it "should not consider a cli setting of a non boolean with a boolean as an argument to be a boolean" do
      # Turn it off first
      @settings[:myval] = "bob"
      @settings.handlearg("--no-myval", "")
      @settings[:myval].should == ""
    end

    it "should flag string settings from the CLI" do
      @settings.handlearg("--myval", "12")
      @settings.set_by_cli?(:myval).should be_true
    end

    it "should flag bool settings from the CLI" do
      @settings[:bool] = false
      @settings.handlearg("--bool")
      @settings.set_by_cli?(:bool).should be_true
    end

    it "should not flag settings memory as from CLI" do
      @settings[:myval] = "12"
      @settings.set_by_cli?(:myval).should be_false
    end

    describe "setbycli" do
      it "should generate a deprecation warning" do
        Puppet.expects(:deprecation_warning)
        @settings.setting(:myval).setbycli = true
      end
      it "should set the value" do
        @settings[:myval] = "blah"
        @settings.setting(:myval).setbycli = true
        @settings.set_by_cli?(:myval).should be_true
      end
      it "should raise error if trying to unset value" do
        @settings.handlearg("--myval", "blah")
        expect do
          @settings.setting(:myval).setbycli = nil
        end.to raise_error ArgumentError, /unset/
      end
    end

    it "should clear the cache when setting getopt-specific values" do
      @settings.define_settings :mysection,
          :one => { :default => "whah", :desc => "yay" },
          :two => { :default => "$one yay", :desc => "bah" }
      @settings.expects(:unsafe_flush_cache)
      @settings[:two].should == "whah yay"
      @settings.handlearg("--one", "else")
      @settings[:two].should == "else yay"
    end

    it "should clear the cache when the preferred_run_mode is changed" do
      @settings.expects(:flush_cache)
      @settings.preferred_run_mode = :master
    end

    it "should not clear other values when setting getopt-specific values" do
      @settings[:myval] = "yay"
      @settings.handlearg("--no-bool", "")
      @settings[:myval].should == "yay"
    end

    it "should clear the list of used sections" do
      @settings.expects(:clearused)
      @settings[:myval] = "yay"
    end

    describe "call_hook" do
      Puppet::Settings::StringSetting.available_call_hook_values.each do |val|
        describe "when :#{val}" do
          describe "and definition invalid" do
            it "should raise error if no hook defined" do
              expect do
                @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :call_hook => val})
              end.to raise_error ArgumentError, /no :hook/
            end
            it "should include the setting name in the error message" do
              expect do
                @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :call_hook => val})
              end.to raise_error ArgumentError, /for :hooker/
            end
          end
          describe "and definition valid" do
            before(:each) do
              hook_values = []
              @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :call_hook => val, :hook => lambda { |v| hook_values << v  }})
            end

            it "should call the hook when value written" do
              @settings.setting(:hooker).expects(:handle).with("something").once
              @settings[:hooker] = "something"
            end
          end
        end
      end

      it "should have a default value of :on_write_only" do
        @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :hook => lambda { |v| hook_values << v  }})
        @settings.setting(:hooker).call_hook.should == :on_write_only
      end

      describe "when nil" do
        it "should generate a warning" do
          Puppet.expects(:warning)
          @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :call_hook => nil, :hook => lambda { |v| hook_values << v  }})
        end
        it "should use default" do
          @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :call_hook => nil, :hook => lambda { |v| hook_values << v  }})
          @settings.setting(:hooker).call_hook.should == :on_write_only
        end
      end

      describe "when invalid" do
        it "should raise an error" do
          expect do
            @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :call_hook => :foo, :hook => lambda { |v| hook_values << v  }})
          end.to raise_error ArgumentError, /invalid.*call_hook/i
        end
      end

      describe "when :on_define_and_write" do
        it "should call the hook at definition" do
          hook_values = []
          @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :call_hook => :on_define_and_write, :hook => lambda { |v| hook_values << v  }})
          @settings.setting(:hooker).call_hook.should == :on_define_and_write
          hook_values.should == %w{yay}
        end
      end

      describe "when :on_initialize_and_write" do
        before(:each) do
          @hook_values = []
          @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :call_hook => :on_initialize_and_write, :hook => lambda { |v| @hook_values << v  }})
        end

        it "should not call the hook at definition" do
          @hook_values.should == []
          @hook_values.should_not == %w{yay}
        end

        it "should call the hook at initialization" do
          app_defaults = {}
          Puppet::Settings::REQUIRED_APP_SETTINGS.each do |key|
            app_defaults[key] = "foo"
          end
          app_defaults[:run_mode] = :user
          @settings.define_settings(:main, PuppetSpec::Settings::TEST_APP_DEFAULT_DEFINITIONS)

          @settings.setting(:hooker).expects(:handle).with("yay").once

          @settings.initialize_app_defaults app_defaults
        end
      end
    end

    describe "call_on_define" do
      [true, false].each do |val|
        describe "to #{val}" do
          it "should generate a deprecation warning" do
            Puppet.expects(:deprecation_warning)
            values = []
            @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :call_on_define => val, :hook => lambda { |v| values << v }})
          end

          it "should should set call_hook" do
            values = []
            name = "hooker_#{val}".to_sym
            @settings.define_settings(:section, name => {:default => "yay", :desc => "boo", :call_on_define => val, :hook => lambda { |v| values << v }})

            @settings.setting(name).call_hook.should == :on_define_and_write if val
            @settings.setting(name).call_hook.should == :on_write_only unless val
          end
        end
      end
    end

    it "should call passed blocks when values are set" do
      values = []
      @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :hook => lambda { |v| values << v }})
      values.should == []

      @settings[:hooker] = "something"
      values.should == %w{something}
    end

    it "should call passed blocks when values are set via the command line" do
      values = []
      @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :hook => lambda { |v| values << v }})
      values.should == []

      @settings.handlearg("--hooker", "yay")

      values.should == %w{yay}
    end

    it "should provide an option to call passed blocks during definition" do
      values = []
      @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :call_hook => :on_define_and_write, :hook => lambda { |v| values << v }})
      values.should == %w{yay}
    end

    it "should pass the fully interpolated value to the hook when called on definition" do
      values = []
      @settings.define_settings(:section, :one => { :default => "test", :desc => "a" })
      @settings.define_settings(:section, :hooker => {:default => "$one/yay", :desc => "boo", :call_hook => :on_define_and_write, :hook => lambda { |v| values << v }})
      values.should == %w{test/yay}
    end

    it "should munge values using the setting-specific methods" do
      @settings[:bool] = "false"
      @settings[:bool].should == false
    end

    it "should prefer cli values to values set in Ruby code" do
      @settings.handlearg("--myval", "cliarg")
      @settings[:myval] = "memarg"
      @settings[:myval].should == "cliarg"
    end

    it "should clear the list of environments" do
      Puppet::Node::Environment.expects(:clear).at_least(1)
      @settings[:myval] = "memarg"
    end

    it "should raise an error if we try to set a setting that hasn't been defined'" do
      lambda{
        @settings[:why_so_serious] = "foo"
      }.should raise_error(ArgumentError, /unknown configuration parameter/)
    end
  end

  describe "when returning values" do
    before do
      @settings = Puppet::Settings.new
      @settings.define_settings :section,
          :config => { :type => :file, :default => "/my/file", :desc => "eh" },
          :one    => { :default => "ONE", :desc => "a" },
          :two    => { :default => "$one TWO", :desc => "b"},
          :three  => { :default => "$one $two THREE", :desc => "c"},
          :four   => { :default => "$two $three FOUR", :desc => "d"},
          :five   => { :default => nil, :desc => "e" }
      Puppet::FileSystem::File.stubs(:exist?).returns true
    end

    describe "call_on_define" do
      it "should generate a deprecation warning" do
        Puppet.expects(:deprecation_warning)
        @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :hook => lambda { |v| hook_values << v  }})
        @settings.setting(:hooker).call_on_define
      end

      Puppet::Settings::StringSetting.available_call_hook_values.each do |val|
        it "should match value for call_hook => :#{val}" do
          hook_values = []
          @settings.define_settings(:section, :hooker => {:default => "yay", :desc => "boo", :call_hook => val, :hook => lambda { |v| hook_values << v  }})
          @settings.setting(:hooker).call_on_define.should == @settings.setting(:hooker).call_hook_on_define?
        end
      end
    end

    it "should provide a mechanism for returning set values" do
      @settings[:one] = "other"
      @settings[:one].should == "other"
    end

    it "should interpolate default values for other parameters into returned parameter values" do
      @settings[:one].should == "ONE"
      @settings[:two].should == "ONE TWO"
      @settings[:three].should == "ONE ONE TWO THREE"
    end

    it "should interpolate default values that themselves need to be interpolated" do
      @settings[:four].should == "ONE TWO ONE ONE TWO THREE FOUR"
    end

    it "should provide a method for returning uninterpolated values" do
      @settings[:two] = "$one tw0"
      @settings.uninterpolated_value(:two).should  == "$one tw0"
      @settings.uninterpolated_value(:four).should == "$two $three FOUR"
    end

    it "should interpolate set values for other parameters into returned parameter values" do
      @settings[:one] = "on3"
      @settings[:two] = "$one tw0"
      @settings[:three] = "$one $two thr33"
      @settings[:four] = "$one $two $three f0ur"
      @settings[:one].should == "on3"
      @settings[:two].should == "on3 tw0"
      @settings[:three].should == "on3 on3 tw0 thr33"
      @settings[:four].should == "on3 on3 tw0 on3 on3 tw0 thr33 f0ur"
    end

    it "should not cache interpolated values such that stale information is returned" do
      @settings[:two].should == "ONE TWO"
      @settings[:one] = "one"
      @settings[:two].should == "one TWO"
    end

    describe "caching values that evaluate to false" do
      it "caches nil" do
        @settings.expects(:convert).once.returns nil
        @settings[:five].should be_nil
        @settings[:five].should be_nil
      end

      it "caches false" do
        @settings.expects(:convert).once.returns false
        @settings[:five].should == false
        @settings[:five].should == false
      end
    end

    it "should not cache values such that information from one environment is returned for another environment" do
      text = "[env1]\none = oneval\n[env2]\none = twoval\n"
      @settings.stubs(:read_file).returns(text)
      @settings.send(:parse_config_files)

      @settings.value(:one, "env1").should == "oneval"
      @settings.value(:one, "env2").should == "twoval"
    end

    it "should have a run_mode that defaults to user" do
      @settings.preferred_run_mode.should == :user
    end

    describe "setbycli" do
      it "should generate a deprecation warning" do
        @settings.handlearg("--one", "blah")
        Puppet.expects(:deprecation_warning)
        @settings.setting(:one).setbycli
      end
      it "should be true" do
        @settings.handlearg("--one", "blah")
        @settings.setting(:one).setbycli.should be_true
      end
    end
  end

  describe "when choosing which value to return" do
    before do
      @settings = Puppet::Settings.new
      @settings.define_settings :section,
        :config => { :type => :file, :default => "/my/file", :desc => "a" },
        :one => { :default => "ONE", :desc => "a" },
        :two => { :default => "TWO", :desc => "b" }
      Puppet::FileSystem::File.stubs(:exist?).returns true
      @settings.preferred_run_mode = :agent
    end

    it "should return default values if no values have been set" do
      @settings[:one].should == "ONE"
    end

    it "should return values set on the cli before values set in the configuration file" do
      text = "[main]\none = fileval\n"
      @settings.stubs(:read_file).returns(text)
      @settings.handlearg("--one", "clival")
      @settings.send(:parse_config_files)

      @settings[:one].should == "clival"
    end

    it "should return values set on the cli before values set in Ruby" do
      @settings[:one] = "rubyval"
      @settings.handlearg("--one", "clival")
      @settings[:one].should == "clival"
    end

    it "should return values set in the mode-specific section before values set in the main section" do
      text = "[main]\none = mainval\n[agent]\none = modeval\n"
      @settings.stubs(:read_file).returns(text)
      @settings.send(:parse_config_files)

      @settings[:one].should == "modeval"
    end

    it "should not return values outside of its search path" do
      text = "[other]\none = oval\n"
      file = "/some/file"
      @settings.stubs(:read_file).returns(text)
      @settings.send(:parse_config_files)
      @settings[:one].should == "ONE"
    end

    it "should return values in a specified environment" do
      text = "[env]\none = envval\n"
      @settings.stubs(:read_file).returns(text)
      @settings.send(:parse_config_files)
      @settings.value(:one, "env").should == "envval"
    end

    it 'should use the current environment for $environment' do
      @settings.define_settings :main, :myval => { :default => "$environment/foo", :desc => "mydocs" }

      @settings.value(:myval, "myenv").should == "myenv/foo"
    end

    it "should interpolate found values using the current environment" do
      text = "[main]\none = mainval\n[myname]\none = nameval\ntwo = $one/two\n"
      @settings.stubs(:read_file).returns(text)
      @settings.send(:parse_config_files)

      @settings.value(:two, "myname").should == "nameval/two"
    end

    it "should return values in a specified environment before values in the main or name sections" do
      text = "[env]\none = envval\n[main]\none = mainval\n[myname]\none = nameval\n"
      @settings.stubs(:read_file).returns(text)
      @settings.send(:parse_config_files)
      @settings.value(:one, "env").should == "envval"
    end
  end


  describe "when locating config files" do
    before do
      @settings = Puppet::Settings.new
    end

    describe "when root" do
      it "should look for the main config file default location config settings haven't been overridden'" do
        Puppet.features.stubs(:root?).returns(true)
        Puppet::FileSystem::File.expects(:exist?).with(main_config_file_default_location).returns(false)
        Puppet::FileSystem::File.expects(:exist?).with(user_config_file_default_location).never

        @settings.send(:parse_config_files)
      end
    end

    describe "when not root" do
      it "should look for user config file default location if config settings haven't been overridden'" do
        Puppet.features.stubs(:root?).returns(false)

        seq = sequence "load config files"
        Puppet::FileSystem::File.expects(:exist?).with(user_config_file_default_location).returns(false).in_sequence(seq)

        @settings.send(:parse_config_files)
      end
    end
  end

  describe "when parsing its configuration" do
    before do
      @settings = Puppet::Settings.new
      @settings.stubs(:service_user_available?).returns true
      @settings.stubs(:service_group_available?).returns true
      @file = make_absolute("/some/file")
      @userconfig = make_absolute("/test/userconfigfile")
      @settings.define_settings :section, :user => { :default => "suser", :desc => "doc" }, :group => { :default => "sgroup", :desc => "doc" }
      @settings.define_settings :section,
          :config => { :type => :file, :default => @file, :desc => "eh" },
          :one => { :default => "ONE", :desc => "a" },
          :two => { :default => "$one TWO", :desc => "b" },
          :three => { :default => "$one $two THREE", :desc => "c" }
      @settings.stubs(:user_config_file).returns(@userconfig)
      Puppet::FileSystem::File.stubs(:exist?).with(@file).returns true
      Puppet::FileSystem::File.stubs(:exist?).with(@userconfig).returns false
    end

    it "should not ignore the report setting" do
      @settings.define_settings :section, :report => { :default => "false", :desc => "a" }
      # This is needed in order to make sure we pass on windows
      myfile = File.expand_path(@file)
      @settings[:config] = myfile
      text = <<-CONF
        [puppetd]
          report=true
      CONF
      Puppet::FileSystem::File.expects(:exist?).with(myfile).returns(true)
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)
      @settings[:report].should be_true
    end

    it "should use its current ':config' value for the file to parse" do
      myfile = make_absolute("/my/file") # do not stub expand_path here, as this leads to a stack overflow, when mocha tries to use it
      @settings[:config] = myfile

      Puppet::FileSystem::File.expects(:exist?).with(myfile).returns(true)

      File.expects(:read).with(myfile).returns "[main]"

      @settings.send(:parse_config_files)
    end

    it "should not try to parse non-existent files" do
      Puppet::FileSystem::File.expects(:exist?).with(@file).returns false

      File.expects(:read).with(@file).never

      @settings.send(:parse_config_files)
    end

    it "should return values set in the configuration file" do
      text = "[main]
      one = fileval
      "
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)
      @settings[:one].should == "fileval"
    end

    #484 - this should probably be in the regression area
    it "should not throw an exception on unknown parameters" do
      text = "[main]\nnosuchparam = mval\n"
      @settings.expects(:read_file).returns(text)
      lambda { @settings.send(:parse_config_files) }.should_not raise_error
    end

    it "should convert booleans in the configuration file into Ruby booleans" do
      text = "[main]
      one = true
      two = false
      "
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)
      @settings[:one].should == true
      @settings[:two].should == false
    end

    it "should convert integers in the configuration file into Ruby Integers" do
      text = "[main]
      one = 65
      "
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)
      @settings[:one].should == 65
    end

    it "should support specifying all metadata (owner, group, mode) in the configuration file" do
      @settings.define_settings :section, :myfile => { :type => :file, :default => make_absolute("/myfile"), :desc => "a" }

      otherfile = make_absolute("/other/file")
      text = "[main]
      myfile = #{otherfile} {owner = service, group = service, mode = 644}
      "
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)
      @settings[:myfile].should == otherfile
      @settings.metadata(:myfile).should == {:owner => "suser", :group => "sgroup", :mode => "644"}
    end

    it "should support specifying a single piece of metadata (owner, group, or mode) in the configuration file" do
      @settings.define_settings :section, :myfile => { :type => :file, :default => make_absolute("/myfile"), :desc => "a" }

      otherfile = make_absolute("/other/file")
      text = "[main]
      myfile = #{otherfile} {owner = service}
      "
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)
      @settings[:myfile].should == otherfile
      @settings.metadata(:myfile).should == {:owner => "suser"}
    end

    it "should support loading metadata (owner, group, or mode) from a run_mode section in the configuration file" do
      default_values = {}
      PuppetSpec::Settings::TEST_APP_DEFAULT_DEFINITIONS.keys.each do |key|
        default_values[key] = 'default value'
      end
      @settings.define_settings :main, PuppetSpec::Settings::TEST_APP_DEFAULT_DEFINITIONS
      @settings.define_settings :master, :myfile => { :type => :file, :default => make_absolute("/myfile"), :desc => "a" }

      otherfile = make_absolute("/other/file")
      text = "[master]
      myfile = #{otherfile} {mode = 664}
      "
      @settings.expects(:read_file).returns(text)

      # will start initialization as user
      @settings.preferred_run_mode.should == :user
      @settings.send(:parse_config_files)

      # change app run_mode to master
      @settings.initialize_app_defaults(default_values.merge(:run_mode => :master))
      @settings.preferred_run_mode.should == :master

      # initializing the app should have reloaded the metadata based on run_mode
      @settings[:myfile].should == otherfile
      @settings.metadata(:myfile).should == {:mode => "664"}
    end

    it "should call hooks associated with values set in the configuration file" do
      values = []
      @settings.define_settings :section, :mysetting => {:default => "defval", :desc => "a", :hook => proc { |v| values << v }}

      text = "[main]
      mysetting = setval
      "
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)
      values.should == ["setval"]
    end

    it "should not call the same hook for values set multiple times in the configuration file" do
      values = []
      @settings.define_settings :section, :mysetting => {:default => "defval", :desc => "a", :hook => proc { |v| values << v }}

      text = "[user]
      mysetting = setval
      [main]
      mysetting = other
      "
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)
      values.should == ["setval"]
    end

    it "should pass the environment-specific value to the hook when one is available" do
      values = []
      @settings.define_settings :section, :mysetting => {:default => "defval", :desc => "a", :hook => proc { |v| values << v }}
      @settings.define_settings :section, :environment => { :default => "yay", :desc => "a" }
      @settings.define_settings :section, :environments => { :default => "yay,foo", :desc => "a" }

      text = "[main]
      mysetting = setval
      [yay]
      mysetting = other
      "
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)
      values.should == ["other"]
    end

    it "should pass the interpolated value to the hook when one is available" do
      values = []
      @settings.define_settings :section, :base => {:default => "yay", :desc => "a", :hook => proc { |v| values << v }}
      @settings.define_settings :section, :mysetting => {:default => "defval", :desc => "a", :hook => proc { |v| values << v }}

      text = "[main]
      mysetting = $base/setval
      "
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)
      values.should == ["yay/setval"]
    end

    it "should allow hooks invoked at parse time to be deferred" do
      hook_invoked = false
      @settings.define_settings :section, :deferred  => {:desc => '',
                                                         :hook => proc { |v| hook_invoked = true },
                                                         :call_hook => :on_initialize_and_write, }

      @settings.define_settings(:main,
        :logdir       => { :type => :directory, :default => nil, :desc => "logdir" },
        :confdir      => { :type => :directory, :default => nil, :desc => "confdir" },
        :vardir       => { :type => :directory, :default => nil, :desc => "vardir" })

      text = <<-EOD
      [main]
      deferred=$confdir/goose
      EOD

      @settings.stubs(:read_file).returns(text)
      @settings.initialize_global_settings

      hook_invoked.should be_false

      @settings.initialize_app_defaults(:logdir => '/path/to/logdir', :confdir => '/path/to/confdir', :vardir => '/path/to/vardir')

      hook_invoked.should be_true
      @settings[:deferred].should eq File.expand_path('/path/to/confdir/goose')
    end

    it "should allow empty values" do
      @settings.define_settings :section, :myarg => { :default => "myfile", :desc => "a" }

      text = "[main]
      myarg =
      "
      @settings.stubs(:read_file).returns(text)
      @settings.send(:parse_config_files)
      @settings[:myarg].should == ""
    end

    describe "and when reading a non-positive filetimeout value from the config file" do
      before do
        @settings.define_settings :foo, :filetimeout => { :default => 5, :desc => "eh" }

        somefile = "/some/file"
        text = "[main]
        filetimeout = -1
        "
        File.expects(:read).with(somefile).returns(text)
        File.expects(:expand_path).with(somefile).returns somefile
        @settings[:config] = somefile
      end
    end
  end


  describe "when there are multiple config files" do
    let(:main_config_text) { "[main]\none = main\ntwo = main2" }
    let(:user_config_text) { "[main]\none = user\n" }
    let(:seq) { sequence "config_file_sequence" }

    before :each do
      @settings = Puppet::Settings.new
      @settings.define_settings(:section,
          { :confdir => { :default => nil,                    :desc => "Conf dir" },
            :config  => { :default => "$confdir/puppet.conf", :desc => "Config" },
            :one     => { :default => "ONE",                  :desc => "a" },
            :two     => { :default => "TWO",                  :desc => "b" }, })
    end

    context "running non-root without explicit config file" do
      before :each do
        Puppet.features.stubs(:root?).returns(false)
        Puppet::FileSystem::File.expects(:exist?).
          with(user_config_file_default_location).
          returns(true).in_sequence(seq)
        @settings.expects(:read_file).
          with(user_config_file_default_location).
          returns(user_config_text).in_sequence(seq)
      end

      it "should return values from the user config file" do
        @settings.send(:parse_config_files)
        @settings[:one].should == "user"
      end

      it "should not return values from the main config file" do
        @settings.send(:parse_config_files)
        @settings[:two].should == "TWO"
      end
    end

    context "running as root without explicit config file" do
      before :each do
        Puppet.features.stubs(:root?).returns(true)
        Puppet::FileSystem::File.expects(:exist?).
          with(main_config_file_default_location).
          returns(true).in_sequence(seq)
        @settings.expects(:read_file).
          with(main_config_file_default_location).
          returns(main_config_text).in_sequence(seq)
      end

      it "should return values from the main config file" do
        @settings.send(:parse_config_files)
        @settings[:one].should == "main"
      end

      it "should not return values from the user config file" do
        @settings.send(:parse_config_files)
        @settings[:two].should == "main2"
      end
    end

    context "running with an explicit config file as a user (e.g. Apache + Passenger)" do
      before :each do
        Puppet.features.stubs(:root?).returns(false)
        @settings[:confdir] = File.dirname(main_config_file_default_location)
        Puppet::FileSystem::File.expects(:exist?).
          with(main_config_file_default_location).
          returns(true).in_sequence(seq)
        @settings.expects(:read_file).
          with(main_config_file_default_location).
          returns(main_config_text).in_sequence(seq)
      end

      it "should return values from the main config file" do
        @settings.send(:parse_config_files)
        @settings[:one].should == "main"
      end

      it "should not return values from the user config file" do
        @settings.send(:parse_config_files)
        @settings[:two].should == "main2"
      end
    end
  end

  describe "when reparsing its configuration" do
    before do
      @file = make_absolute("/test/file")
      @userconfig = make_absolute("/test/userconfigfile")
      @settings = Puppet::Settings.new
      @settings.define_settings :section,
          :config => { :type => :file, :default => @file, :desc => "a" },
          :one => { :default => "ONE", :desc => "a" },
          :two => { :default => "$one TWO", :desc => "b" },
          :three => { :default => "$one $two THREE", :desc => "c" }
      Puppet::FileSystem::File.stubs(:exist?).with(@file).returns true
      Puppet::FileSystem::File.stubs(:exist?).with(@userconfig).returns false
      @settings.stubs(:user_config_file).returns(@userconfig)
    end

    it "does not create the WatchedFile instance and should not parse if the file does not exist" do
      Puppet::FileSystem::File.expects(:exist?).with(@file).returns false
      Puppet::Util::WatchedFile.expects(:new).never

      @settings.expects(:parse_config_files).never

      @settings.reparse_config_files
    end

    context "and watched file exists" do
      before do
        @watched_file = Puppet::Util::WatchedFile.new(@file)
        Puppet::Util::WatchedFile.expects(:new).with(@file).returns @watched_file
      end

      it "uses a WatchedFile instance to determine if the file has changed" do
        @watched_file.expects(:changed?)

        @settings.reparse_config_files
      end

      it "does not reparse if the file has not changed" do
        @watched_file.expects(:changed?).returns false

        @settings.expects(:parse_config_files).never

        @settings.reparse_config_files
      end

      it "reparses if the file has changed" do
        @watched_file.expects(:changed?).returns true

        @settings.expects(:unsafe_parse).with(@file)

        @settings.reparse_config_files
      end

      it "replaces in-memory values with on-file values" do
        @watched_file.stubs(:changed?).returns(true)
        @settings[:one] = "init"

        # Now replace the value
        text = "[main]\none = disk-replace\n"
        @settings.stubs(:read_file).returns(text)
        @settings.reparse_config_files
        @settings[:one].should == "disk-replace"
      end
    end

    it "should retain parameters set by cli when configuration files are reparsed" do
      @settings.handlearg("--one", "clival")

      text = "[main]\none = on-disk\n"
      @settings.stubs(:read_file).returns(text)
      @settings.send(:parse_config_files)

      @settings[:one].should == "clival"
    end

    it "should remove in-memory values that are no longer set in the file" do
      # Init the value
      text = "[main]\none = disk-init\n"
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)
      @settings[:one].should == "disk-init"

      # Now replace the value
      text = "[main]\ntwo = disk-replace\n"
      @settings.expects(:read_file).returns(text)
      @settings.send(:parse_config_files)

      # The originally-overridden value should be replaced with the default
      @settings[:one].should == "ONE"

      # and we should now have the new value in memory
      @settings[:two].should == "disk-replace"
    end

    it "should retain in-memory values if the file has a syntax error" do
      # Init the value
      text = "[main]\none = initial-value\n"
      @settings.expects(:read_file).with(@file).returns(text)
      @settings.send(:parse_config_files)
      @settings[:one].should == "initial-value"

      # Now replace the value with something bogus
      text = "[main]\nkenny = killed-by-what-follows\n1 is 2, blah blah florp\n"
      @settings.expects(:read_file).with(@file).returns(text)
      @settings.send(:parse_config_files)

      # The originally-overridden value should not be replaced with the default
      @settings[:one].should == "initial-value"

      # and we should not have the new value in memory
      @settings[:kenny].should be_nil
    end
  end

  it "should provide a method for creating a catalog of resources from its configuration" do
    Puppet::Settings.new.should respond_to(:to_catalog)
  end

  describe "when creating a catalog" do
    before do
      @settings = Puppet::Settings.new
      @settings.stubs(:service_user_available?).returns true
      @prefix = Puppet.features.posix? ? "" : "C:"
    end

    it "should add all file resources to the catalog if no sections have been specified" do
      @settings.define_settings :main,
          :maindir => { :type => :directory, :default => @prefix+"/maindir", :desc => "a"},
          :seconddir => { :type => :directory, :default => @prefix+"/seconddir", :desc => "a"}
      @settings.define_settings :other,
          :otherdir => { :type => :directory, :default => @prefix+"/otherdir", :desc => "a" }

      catalog = @settings.to_catalog

      [@prefix+"/maindir", @prefix+"/seconddir", @prefix+"/otherdir"].each do |path|
        catalog.resource(:file, path).should be_instance_of(Puppet::Resource)
      end
    end

    it "should add only files in the specified sections if section names are provided" do
      @settings.define_settings :main, :maindir => { :type => :directory, :default => @prefix+"/maindir", :desc => "a" }
      @settings.define_settings :other, :otherdir => { :type => :directory, :default => @prefix+"/otherdir", :desc => "a" }
      catalog = @settings.to_catalog(:main)
      catalog.resource(:file, @prefix+"/otherdir").should be_nil
      catalog.resource(:file, @prefix+"/maindir").should be_instance_of(Puppet::Resource)
    end

    it "should not try to add the same file twice" do
      @settings.define_settings :main, :maindir => { :type => :directory, :default => @prefix+"/maindir", :desc => "a" }
      @settings.define_settings :other, :otherdir => { :type => :directory, :default => @prefix+"/maindir", :desc => "a" }
      lambda { @settings.to_catalog }.should_not raise_error
    end

    it "should ignore files whose :to_resource method returns nil" do
      @settings.define_settings :main, :maindir => { :type => :directory, :default => @prefix+"/maindir", :desc => "a" }
      @settings.setting(:maindir).expects(:to_resource).returns nil

      Puppet::Resource::Catalog.any_instance.expects(:add_resource).never
      @settings.to_catalog
    end

    describe "on Microsoft Windows" do
      before :each do
        Puppet.features.stubs(:root?).returns true
        Puppet.features.stubs(:microsoft_windows?).returns true

        @settings.define_settings :foo,
            :mkusers => { :type => :boolean, :default => true, :desc => "e" },
            :user => { :default => "suser", :desc => "doc" },
            :group => { :default => "sgroup", :desc => "doc" }
        @settings.define_settings :other,
            :otherdir => { :type => :directory, :default => "/otherdir", :desc => "a", :owner => "service", :group => "service"}

        @catalog = @settings.to_catalog
      end

      it "it should not add users and groups to the catalog" do
        @catalog.resource(:user, "suser").should be_nil
        @catalog.resource(:group, "sgroup").should be_nil
      end
    end

    describe "when adding users and groups to the catalog" do
      before do
        Puppet.features.stubs(:root?).returns true
        Puppet.features.stubs(:microsoft_windows?).returns false

        @settings.define_settings :foo,
            :mkusers => { :type => :boolean, :default => true, :desc => "e" },
            :user => { :default => "suser", :desc => "doc" },
            :group => { :default => "sgroup", :desc => "doc" }
        @settings.define_settings :other, :otherdir => {:type => :directory, :default => "/otherdir", :desc => "a", :owner => "service", :group => "service"}

        @catalog = @settings.to_catalog
      end

      it "should add each specified user and group to the catalog if :mkusers is a valid setting, is enabled, and we're running as root" do
        @catalog.resource(:user, "suser").should be_instance_of(Puppet::Resource)
        @catalog.resource(:group, "sgroup").should be_instance_of(Puppet::Resource)
      end

      it "should only add users and groups to the catalog from specified sections" do
        @settings.define_settings :yay, :yaydir => { :type => :directory, :default => "/yaydir", :desc => "a", :owner => "service", :group => "service"}
        catalog = @settings.to_catalog(:other)
        catalog.resource(:user, "jane").should be_nil
        catalog.resource(:group, "billy").should be_nil
      end

      it "should not add users or groups to the catalog if :mkusers not running as root" do
        Puppet.features.stubs(:root?).returns false

        catalog = @settings.to_catalog
        catalog.resource(:user, "suser").should be_nil
        catalog.resource(:group, "sgroup").should be_nil
      end

      it "should not add users or groups to the catalog if :mkusers is not a valid setting" do
        Puppet.features.stubs(:root?).returns true
        settings = Puppet::Settings.new
        settings.define_settings :other, :otherdir => {:type => :directory, :default => "/otherdir", :desc => "a", :owner => "service", :group => "service"}

        catalog = settings.to_catalog
        catalog.resource(:user, "suser").should be_nil
        catalog.resource(:group, "sgroup").should be_nil
      end

      it "should not add users or groups to the catalog if :mkusers is a valid setting but is disabled" do
        @settings[:mkusers] = false

        catalog = @settings.to_catalog
        catalog.resource(:user, "suser").should be_nil
        catalog.resource(:group, "sgroup").should be_nil
      end

      it "should not try to add users or groups to the catalog twice" do
        @settings.define_settings :yay, :yaydir => {:type => :directory, :default => "/yaydir", :desc => "a", :owner => "service", :group => "service"}

        # This would fail if users/groups were added twice
        lambda { @settings.to_catalog }.should_not raise_error
      end

      it "should set :ensure to :present on each created user and group" do
        @catalog.resource(:user, "suser")[:ensure].should == :present
        @catalog.resource(:group, "sgroup")[:ensure].should == :present
      end

      it "should set each created user's :gid to the service group" do
        @settings.to_catalog.resource(:user, "suser")[:gid].should == "sgroup"
      end

      it "should not attempt to manage the root user" do
        Puppet.features.stubs(:root?).returns true
        @settings.define_settings :foo, :foodir => {:type => :directory, :default => "/foodir", :desc => "a", :owner => "root", :group => "service"}

        @settings.to_catalog.resource(:user, "root").should be_nil
      end
    end
  end

  it "should be able to be converted to a manifest" do
    Puppet::Settings.new.should respond_to(:to_manifest)
  end

  describe "when being converted to a manifest" do
    it "should produce a string with the code for each resource joined by two carriage returns" do
      @settings = Puppet::Settings.new
      @settings.define_settings :main,
          :maindir => { :type => :directory, :default => "/maindir", :desc => "a"},
          :seconddir => { :type => :directory, :default => "/seconddir", :desc => "a"}

      main = stub 'main_resource', :ref => "File[/maindir]"
      main.expects(:to_manifest).returns "maindir"
      second = stub 'second_resource', :ref => "File[/seconddir]"
      second.expects(:to_manifest).returns "seconddir"
      @settings.setting(:maindir).expects(:to_resource).returns main
      @settings.setting(:seconddir).expects(:to_resource).returns second

      @settings.to_manifest.split("\n\n").sort.should == %w{maindir seconddir}
    end
  end

  describe "when using sections of the configuration to manage the local host" do
    before do
      @settings = Puppet::Settings.new
      @settings.stubs(:service_user_available?).returns true
      @settings.stubs(:service_group_available?).returns true
      @settings.define_settings :main, :noop => { :default => false, :desc => "", :type => :boolean }
      @settings.define_settings :main,
          :maindir => { :type => :directory, :default => make_absolute("/maindir"), :desc => "a" },
          :seconddir => { :type => :directory, :default => make_absolute("/seconddir"), :desc => "a"}
      @settings.define_settings :main, :user => { :default => "suser", :desc => "doc" }, :group => { :default => "sgroup", :desc => "doc" }
      @settings.define_settings :other, :otherdir => {:type => :directory, :default => make_absolute("/otherdir"), :desc => "a", :owner => "service", :group => "service", :mode => 0755}
      @settings.define_settings :third, :thirddir => { :type => :directory, :default => make_absolute("/thirddir"), :desc => "b"}
      @settings.define_settings :files, :myfile => {:type => :file, :default => make_absolute("/myfile"), :desc => "a", :mode => 0755}
    end

    it "should provide a method that creates directories with the correct modes" do
      Puppet::Util::SUIDManager.expects(:asuser).with("suser", "sgroup").yields
      Dir.expects(:mkdir).with(make_absolute("/otherdir"), 0755)
      @settings.mkdir(:otherdir)
    end

    it "should create a catalog with the specified sections" do
      @settings.expects(:to_catalog).with(:main, :other).returns Puppet::Resource::Catalog.new("foo")
      @settings.use(:main, :other)
    end

    it "should canonicalize the sections" do
      @settings.expects(:to_catalog).with(:main, :other).returns Puppet::Resource::Catalog.new("foo")
      @settings.use("main", "other")
    end

    it "should ignore sections that have already been used" do
      @settings.expects(:to_catalog).with(:main).returns Puppet::Resource::Catalog.new("foo")
      @settings.use(:main)
      @settings.expects(:to_catalog).with(:other).returns Puppet::Resource::Catalog.new("foo")
      @settings.use(:main, :other)
    end

    it "should convert the created catalog to a RAL catalog" do
      @catalog = Puppet::Resource::Catalog.new("foo")
      @settings.expects(:to_catalog).with(:main).returns @catalog

      @catalog.expects(:to_ral).returns @catalog
      @settings.use(:main)
    end

    it "should specify that it is not managing a host catalog" do
      catalog = Puppet::Resource::Catalog.new("foo")
      catalog.expects(:apply)
      @settings.expects(:to_catalog).returns catalog

      catalog.stubs(:to_ral).returns catalog

      catalog.expects(:host_config=).with false

      @settings.use(:main)
    end

    it "should support a method for re-using all currently used sections" do
      @settings.expects(:to_catalog).with(:main, :third).times(2).returns Puppet::Resource::Catalog.new("foo")

      @settings.use(:main, :third)
      @settings.reuse
    end

    it "should fail with an appropriate message if any resources fail" do
      @catalog = Puppet::Resource::Catalog.new("foo")
      @catalog.stubs(:to_ral).returns @catalog
      @settings.expects(:to_catalog).returns @catalog

      @trans = mock("transaction")
      @catalog.expects(:apply).yields(@trans)

      @trans.expects(:any_failed?).returns(true)

      report = mock 'report'
      @trans.expects(:report).returns report

      log = mock 'log', :to_s => "My failure", :level => :err
      report.expects(:logs).returns [log]

      @settings.expects(:raise).with { |msg| msg.include?("My failure") }
      @settings.use(:whatever)
    end
  end

  describe "when dealing with printing configs" do
    before do
      @settings = Puppet::Settings.new
      #these are the magic default values
      @settings.stubs(:value).with(:configprint).returns("")
      @settings.stubs(:value).with(:genconfig).returns(false)
      @settings.stubs(:value).with(:genmanifest).returns(false)
      @settings.stubs(:value).with(:environment).returns(nil)
    end

    describe "when checking print_config?" do
      it "should return false when the :configprint, :genconfig and :genmanifest are not set" do
        @settings.print_configs?.should be_false
      end

      it "should return true when :configprint has a value" do
        @settings.stubs(:value).with(:configprint).returns("something")
        @settings.print_configs?.should be_true
      end

      it "should return true when :genconfig has a value" do
        @settings.stubs(:value).with(:genconfig).returns(true)
        @settings.print_configs?.should be_true
      end

      it "should return true when :genmanifest has a value" do
        @settings.stubs(:value).with(:genmanifest).returns(true)
        @settings.print_configs?.should be_true
      end
    end

    describe "when printing configs" do
      describe "when :configprint has a value" do
        it "should call print_config_options" do
          @settings.stubs(:value).with(:configprint).returns("something")
          @settings.expects(:print_config_options)
          @settings.print_configs
        end

        it "should get the value of the option using the environment" do
          @settings.stubs(:value).with(:configprint).returns("something")
          @settings.stubs(:include?).with("something").returns(true)
          @settings.expects(:value).with(:environment).returns("env")
          @settings.expects(:value).with("something", "env").returns("foo")
          @settings.stubs(:puts).with("foo")
          @settings.print_configs
        end

        it "should print the value of the option" do
          @settings.stubs(:value).with(:configprint).returns("something")
          @settings.stubs(:include?).with("something").returns(true)
          @settings.stubs(:value).with("something", nil).returns("foo")
          @settings.expects(:puts).with("foo")
          @settings.print_configs
        end

        it "should print the value pairs if there are multiple options" do
          @settings.stubs(:value).with(:configprint).returns("bar,baz")
          @settings.stubs(:include?).with("bar").returns(true)
          @settings.stubs(:include?).with("baz").returns(true)
          @settings.stubs(:value).with("bar", nil).returns("foo")
          @settings.stubs(:value).with("baz", nil).returns("fud")
          @settings.expects(:puts).with("bar = foo")
          @settings.expects(:puts).with("baz = fud")
          @settings.print_configs
        end

        it "should return true after printing" do
          @settings.stubs(:value).with(:configprint).returns("something")
          @settings.stubs(:include?).with("something").returns(true)
          @settings.stubs(:value).with("something", nil).returns("foo")
          @settings.stubs(:puts).with("foo")
          @settings.print_configs.should be_true
        end

        it "should return false if a config param is not found" do
          @settings.stubs :puts
          @settings.stubs(:value).with(:configprint).returns("something")
          @settings.stubs(:include?).with("something").returns(false)
          @settings.print_configs.should be_false
        end
      end

      describe "when genconfig is true" do
        before do
          @settings.stubs :puts
        end

        it "should call to_config" do
          @settings.stubs(:value).with(:genconfig).returns(true)
          @settings.expects(:to_config)
          @settings.print_configs
        end

        it "should return true from print_configs" do
          @settings.stubs(:value).with(:genconfig).returns(true)
          @settings.stubs(:to_config)
          @settings.print_configs.should be_true
        end
      end

      describe "when genmanifest is true" do
        before do
          @settings.stubs :puts
        end

        it "should call to_config" do
          @settings.stubs(:value).with(:genmanifest).returns(true)
          @settings.expects(:to_manifest)
          @settings.print_configs
        end

        it "should return true from print_configs" do
          @settings.stubs(:value).with(:genmanifest).returns(true)
          @settings.stubs(:to_manifest)
          @settings.print_configs.should be_true
        end
      end
    end
  end

  describe "when determining if the service user is available" do
    let(:settings) do
      settings = Puppet::Settings.new
      settings.define_settings :main, :user => { :default => nil, :desc => "doc" }
      settings
    end

    def a_user_type_for(username)
      user = mock 'user'
      Puppet::Type.type(:user).expects(:new).with { |args| args[:name] == username }.returns user
      user
    end

    it "should return false if there is no user setting" do
      settings.should_not be_service_user_available
    end

    it "should return false if the user provider says the user is missing" do
      settings[:user] = "foo"

      a_user_type_for("foo").expects(:exists?).returns false

      settings.should_not be_service_user_available
    end

    it "should return true if the user provider says the user is present" do
      settings[:user] = "foo"

      a_user_type_for("foo").expects(:exists?).returns true

      settings.should be_service_user_available
    end

    it "caches the result of determining if the user is present" do
      settings[:user] = "foo"

      a_user_type_for("foo").expects(:exists?).returns true
      settings.should be_service_user_available

      settings.should be_service_user_available
    end
  end

  describe "when determining if the service group is available" do
    let(:settings) do
      settings = Puppet::Settings.new
      settings.define_settings :main, :group => { :default => nil, :desc => "doc" }
      settings
    end

    def a_group_type_for(groupname)
      group = mock 'group'
      Puppet::Type.type(:group).expects(:new).with { |args| args[:name] == groupname }.returns group
      group
    end

    it "should return false if there is no group setting" do
      settings.should_not be_service_group_available
    end

    it "should return false if the group provider says the group is missing" do
      settings[:group] = "foo"

      a_group_type_for("foo").expects(:exists?).returns false

      settings.should_not be_service_group_available
    end

    it "should return true if the group provider says the group is present" do
      settings[:group] = "foo"

      a_group_type_for("foo").expects(:exists?).returns true

      settings.should be_service_group_available
    end

    it "caches the result of determining if the group is present" do
      settings[:group] = "foo"

      a_group_type_for("foo").expects(:exists?).returns true
      settings.should be_service_group_available

      settings.should be_service_group_available
    end
  end

  describe "when dealing with command-line options" do
    let(:settings) { Puppet::Settings.new }

    it "should get options from Puppet.settings.optparse_addargs" do
      settings.expects(:optparse_addargs).returns([])

      settings.send(:parse_global_options, [])
    end

    it "should add options to OptionParser" do
      settings.stubs(:optparse_addargs).returns( [["--option","-o", "Funny Option", :NONE]])
      settings.expects(:handlearg).with("--option", true)
      settings.send(:parse_global_options, ["--option"])
    end

    it "should not die if it sees an unrecognized option, because the app/face may handle it later" do
      expect { settings.send(:parse_global_options, ["--topuppet", "value"]) } .to_not raise_error
    end

    it "should not pass an unrecognized option to handleargs" do
      settings.expects(:handlearg).with("--topuppet", "value").never
      expect { settings.send(:parse_global_options, ["--topuppet", "value"]) } .to_not raise_error
    end

    it "should pass valid puppet settings options to handlearg even if they appear after an unrecognized option" do
      settings.stubs(:optparse_addargs).returns( [["--option","-o", "Funny Option", :NONE]])
      settings.expects(:handlearg).with("--option", true)
      settings.send(:parse_global_options, ["--invalidoption", "--option"])
    end

    it "should transform boolean option to normal form" do
      Puppet::Settings.clean_opt("--[no-]option", true).should == ["--option", true]
    end

    it "should transform boolean option to no- form" do
      Puppet::Settings.clean_opt("--[no-]option", false).should == ["--no-option", false]
    end

    it "should set preferred run mode from --run_mode <foo> string without error" do
      args = ["--run_mode", "master"]
      settings.expects(:handlearg).with("--run_mode", "master").never
      expect { settings.send(:parse_global_options, args) } .to_not raise_error
      Puppet.settings.preferred_run_mode.should == :master
      args.empty?.should == true
    end

    it "should set preferred run mode from --run_mode=<foo> string without error" do
      args = ["--run_mode=master"]
      settings.expects(:handlearg).with("--run_mode", "master").never
      expect { settings.send(:parse_global_options, args) } .to_not raise_error
      Puppet.settings.preferred_run_mode.should == :master
      args.empty?.should == true
    end
  end

  describe "default_certname" do
    describe "using hostname and domainname" do
      before :each do
        Puppet::Settings.stubs(:hostname_fact).returns("testhostname")
        Puppet::Settings.stubs(:domain_fact).returns("domain.test.")
      end

      it "should use both to generate fqdn" do
        Puppet::Settings.default_certname.should =~ /testhostname\.domain\.test/
      end
      it "should remove trailing dots from fqdn" do
        Puppet::Settings.default_certname.should == 'testhostname.domain.test'
      end
    end

    describe "using just hostname" do
      before :each do
        Puppet::Settings.stubs(:hostname_fact).returns("testhostname")
        Puppet::Settings.stubs(:domain_fact).returns("")
      end

      it "should use only hostname to generate fqdn" do
        Puppet::Settings.default_certname.should == "testhostname"
      end
      it "should removing trailing dots from fqdn" do
        Puppet::Settings.default_certname.should == "testhostname"
      end
    end
  end
end
