#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/util/autoload'
require 'fileutils'

class AutoloadIntegrator
  @things = []
  def self.newthing(name)
    @things << name
  end

  def self.thing?(name)
    @things.include? name
  end

  def self.clear
    @things.clear
  end
end

require 'puppet_spec/files'

describe Puppet::Util::Autoload do
  include PuppetSpec::Files

  def with_file(name, *path)
    path = File.join(*path)
    # Now create a file to load
    File.open(path, "w") { |f|
      f.puts "\nAutoloadIntegrator.newthing(:#{name.to_s})\n"
      }
    yield
    File.delete(path)
  end

  def with_loader(name, path)
    dir = tmpfile(name + path)
    $LOAD_PATH << dir
    Dir.mkdir(dir)
    rbdir = File.join(dir, path.to_s)
    Dir.mkdir(rbdir)
    loader = Puppet::Util::Autoload.new(name, path)
    yield rbdir, loader
    Dir.rmdir(rbdir)
    Dir.rmdir(dir)
    $LOAD_PATH.pop
    AutoloadIntegrator.clear
  end

  it "should make instances available by the loading class" do
    loader = Puppet::Util::Autoload.new("foo", "bar")
    Puppet::Util::Autoload["foo"].should == loader
  end

  it "should not fail when asked to load a missing file" do
    Puppet::Util::Autoload.new("foo", "bar").load(:eh).should be_false
  end

  it "should load and return true when it successfully loads a file" do
    with_loader("foo", "bar") { |dir,loader|
      with_file(:mything, dir, "mything.rb") {
        loader.load(:mything).should be_true
        loader.class.should be_loaded("bar/mything")
        AutoloadIntegrator.should be_thing(:mything)
      }
    }
  end

  it "should consider a file loaded when asked for the name without an extension" do
    with_loader("foo", "bar") { |dir,loader|
      with_file(:noext, dir, "noext.rb") {
        loader.load(:noext)
        loader.class.should be_loaded("bar/noext")
      }
    }
  end

  it "should consider a file loaded when asked for the name with an extension" do
    with_loader("foo", "bar") { |dir,loader|
      with_file(:noext, dir, "withext.rb") {
        loader.load(:withext)
        loader.class.should be_loaded("bar/withext.rb")
      }
    }
  end

  it "should be able to load files directly from modules" do
    ## modulepath can't be used until after app settings are initialized, so we need to simulate that:
    Puppet.settings.expects(:app_defaults_initialized?).returns(true).at_least_once

    modulepath = tmpfile("autoload_module_testing")
    libdir = File.join(modulepath, "mymod", "lib", "foo")
    FileUtils.mkdir_p(libdir)

    file = File.join(libdir, "plugin.rb")

    Puppet[:modulepath] = modulepath

    with_loader("foo", "foo") do |dir, loader|
      with_file(:plugin, file.split("/")) do
        loader.load(:plugin)
        loader.class.should be_loaded("foo/plugin.rb")
      end
    end
  end
end
