#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/parser/files'

describe Puppet::Parser::Files do
  include PuppetSpec::Files

  before do
    @basepath = make_absolute("/somepath")
  end

  describe "when searching for templates" do
    it "should return fully-qualified templates directly" do
      Puppet::Parser::Files.expects(:modulepath).never
      Puppet::Parser::Files.find_template(@basepath + "/my/template").should == @basepath + "/my/template"
    end

    it "should return the template from the first found module" do
      mod = mock 'module'
      Puppet::Node::Environment.new.expects(:module).with("mymod").returns mod

      mod.expects(:template).returns("/one/mymod/templates/mytemplate")
      Puppet::Parser::Files.find_template("mymod/mytemplate").should == "/one/mymod/templates/mytemplate"
    end

    it "should return the file in the templatedir if it exists" do
      Puppet[:templatedir] = "/my/templates"
      Puppet[:modulepath] = "/one:/two"
      File.stubs(:directory?).returns(true)
      Puppet::FileSystem::File.stubs(:exist?).returns(true)
      Puppet::Parser::Files.find_template("mymod/mytemplate").should == File.join(Puppet[:templatedir], "mymod/mytemplate")
    end

    it "should not raise an error if no valid templatedir exists and the template exists in a module" do
      mod = mock 'module'
      Puppet::Node::Environment.new.expects(:module).with("mymod").returns mod

      mod.expects(:template).returns("/one/mymod/templates/mytemplate")
      Puppet::Parser::Files.stubs(:templatepath).with(nil).returns(nil)

      Puppet::Parser::Files.find_template("mymod/mytemplate").should == "/one/mymod/templates/mytemplate"
    end

    it "should return unqualified templates if they exist in the template dir" do
      Puppet::FileSystem::File.stubs(:exist?).returns true
      Puppet::Parser::Files.stubs(:templatepath).with(nil).returns(["/my/templates"])
      Puppet::Parser::Files.find_template("mytemplate").should == "/my/templates/mytemplate"
    end

    it "should only return templates if they actually exist" do
      Puppet::FileSystem::File.expects(:exist?).with("/my/templates/mytemplate").returns true
      Puppet::Parser::Files.stubs(:templatepath).with(nil).returns(["/my/templates"])
      Puppet::Parser::Files.find_template("mytemplate").should == "/my/templates/mytemplate"
    end

    it "should return nil when asked for a template that doesn't exist" do
      Puppet::FileSystem::File.expects(:exist?).with("/my/templates/mytemplate").returns false
      Puppet::Parser::Files.stubs(:templatepath).with(nil).returns(["/my/templates"])
      Puppet::Parser::Files.find_template("mytemplate").should be_nil
    end

    it "should search in the template directories before modules" do
      Puppet::FileSystem::File.stubs(:exist?).returns true
      Puppet::Parser::Files.stubs(:templatepath).with(nil).returns(["/my/templates"])
      Puppet::Module.expects(:find).never
      Puppet::Parser::Files.find_template("mytemplate")
    end

    it "should accept relative templatedirs" do
      Puppet::FileSystem::File.stubs(:exist?).returns true
      Puppet[:templatedir] = "my/templates"
      File.expects(:directory?).with(File.expand_path("my/templates")).returns(true)
      Puppet::Parser::Files.find_template("mytemplate").should == File.expand_path("my/templates/mytemplate")
    end

    it "should use the environment templatedir if no module is found and an environment is specified" do
      Puppet::FileSystem::File.stubs(:exist?).returns true
      Puppet::Parser::Files.stubs(:templatepath).with("myenv").returns(["/myenv/templates"])
      Puppet::Parser::Files.find_template("mymod/mytemplate", "myenv").should == "/myenv/templates/mymod/mytemplate"
    end

    it "should use first dir from environment templatedir if no module is found and an environment is specified" do
      Puppet::FileSystem::File.stubs(:exist?).returns true
      Puppet::Parser::Files.stubs(:templatepath).with("myenv").returns(["/myenv/templates", "/two/templates"])
      Puppet::Parser::Files.find_template("mymod/mytemplate", "myenv").should == "/myenv/templates/mymod/mytemplate"
    end

    it "should use a valid dir when templatedir is a path for unqualified templates and the first dir contains template" do
      Puppet::Parser::Files.stubs(:templatepath).returns(["/one/templates", "/two/templates"])
      Puppet::FileSystem::File.expects(:exist?).with("/one/templates/mytemplate").returns(true)
      Puppet::Parser::Files.find_template("mytemplate").should == "/one/templates/mytemplate"
    end

    it "should use a valid dir when templatedir is a path for unqualified templates and only second dir contains template" do
      Puppet::Parser::Files.stubs(:templatepath).returns(["/one/templates", "/two/templates"])
      Puppet::FileSystem::File.expects(:exist?).with("/one/templates/mytemplate").returns(false)
      Puppet::FileSystem::File.expects(:exist?).with("/two/templates/mytemplate").returns(true)
      Puppet::Parser::Files.find_template("mytemplate").should == "/two/templates/mytemplate"
    end

    it "should use the node environment if specified" do
      mod = mock 'module'
      Puppet::Node::Environment.new("myenv").expects(:module).with("mymod").returns mod

      mod.expects(:template).returns("/my/modules/mymod/templates/envtemplate")

      Puppet::Parser::Files.find_template("mymod/envtemplate", "myenv").should == "/my/modules/mymod/templates/envtemplate"
    end

    it "should return nil if no template can be found" do
      Puppet::Parser::Files.find_template("foomod/envtemplate", "myenv").should be_nil
    end

    after { Puppet.settings.clear }
  end

  describe "when searching for manifests" do
    it "should ignore invalid modules" do
      mod = mock 'module'
      env = Puppet::Node::Environment.new
      env.expects(:module).with("mymod").raises(Puppet::Module::InvalidName, "name is invalid")
      Puppet.expects(:value).with(:modulepath).never
      Dir.stubs(:glob).returns %w{foo}

      Puppet::Parser::Files.find_manifests_in_modules("mymod/init.pp", env)
    end
  end

  describe "when searching for manifests in a module" do
    def a_module_in_environment(env, name)
      mod = Puppet::Module.new(name, "/one/#{name}", env)
      env.stubs(:module).with(name).returns mod
      mod.stubs(:match_manifests).with("init.pp").returns(["/one/#{name}/manifests/init.pp"])
    end

    let(:environment) { Puppet::Node::Environment.new }

    it "returns no files when no module is found" do
      module_name, files = Puppet::Parser::Files.find_manifests_in_modules("not_here_module/foo", environment)
      expect(files).to be_empty
      expect(module_name).to be_nil
    end

    it "should return the name of the module and the manifests from the first found module" do
      a_module_in_environment(environment, "mymod")

      Puppet::Parser::Files.find_manifests_in_modules("mymod/init.pp", environment).should ==
        ["mymod", ["/one/mymod/manifests/init.pp"]]
    end

    it "does not find the module when it is a different environment" do
      different_env = Puppet::Node::Environment.new("different")
      a_module_in_environment(environment, "mymod")

      Puppet::Parser::Files.find_manifests_in_modules("mymod/init.pp", different_env).should_not include("mymod")
    end
  end
end
