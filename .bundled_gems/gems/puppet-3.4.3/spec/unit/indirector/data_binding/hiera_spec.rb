require 'spec_helper'
require 'puppet/indirector/data_binding/hiera'

describe Puppet::DataBinding::Hiera do
  include PuppetSpec::Files

  def write_hiera_config(config_file, datadir)
    File.open(config_file, 'w') do |f|
      f.write("---
        :yaml:
          :datadir: #{datadir}
        :hierarchy: ['global', 'invalid']
        :logger: 'noop'
        :backends: ['yaml']
      ")
    end
  end

  def request(key)
    Puppet::Indirector::Request.new(:hiera, :find, key, nil)
  end

  before do
    hiera_config_file = tmpfile("hiera.yaml")
    Puppet.settings[:hiera_config] = hiera_config_file
    write_hiera_config(hiera_config_file, my_fixture_dir)
  end

  after do
    Puppet::DataBinding::Hiera.instance_variable_set(:@hiera, nil)
  end

  it "should have documentation" do
    Puppet::DataBinding::Hiera.doc.should_not be_nil
  end

  it "should be registered with the data_binding indirection" do
    indirection = Puppet::Indirector::Indirection.instance(:data_binding)
    Puppet::DataBinding::Hiera.indirection.should equal(indirection)
  end

  it "should have its name set to :hiera" do
    Puppet::DataBinding::Hiera.name.should == :hiera
  end
  it "should be the default data_binding terminus" do
    Puppet.settings[:data_binding_terminus].should == :hiera
  end

  it "should raise an error if we don't have the hiera feature" do
    Puppet.features.expects(:hiera?).returns(false)
    lambda { Puppet::DataBinding::Hiera.new }.should raise_error RuntimeError,
      "Hiera terminus not supported without hiera library"
  end

  describe "the behavior of the hiera_config method", :if => Puppet.features.hiera? do
    it "should override the logger and set it to puppet" do
      Puppet::DataBinding::Hiera.hiera_config[:logger].should == "puppet"
    end

    context "when the Hiera configuration file does not exist" do
      let(:path) { File.expand_path('/doesnotexist') }

      before do
        Puppet.settings[:hiera_config] = path
      end

      it "should log a warning" do
        Puppet.expects(:warning).with(
         "Config file #{path} not found, using Hiera defaults")
        Puppet::DataBinding::Hiera.hiera_config
      end

      it "should only configure the logger and set it to puppet" do
        Puppet.expects(:warning).with(
         "Config file #{path} not found, using Hiera defaults")
        Puppet::DataBinding::Hiera.hiera_config.should == { :logger => 'puppet' }
      end
    end
  end

  describe "the behavior of the find method", :if => Puppet.features.hiera? do

    let(:data_binder) { Puppet::DataBinding::Hiera.new }

    it "should support looking up an integer" do
      data_binder.find(request("integer")).should == 3000
    end

    it "should support looking up a string" do
      data_binder.find(request("string")).should == 'apache'
    end

    it "should support looking up an array" do
      data_binder.find(request("array")).should == [
        '0.ntp.puppetlabs.com',
        '1.ntp.puppetlabs.com',
      ]
    end

    it "should support looking up a hash" do
      data_binder.find(request("hash")).should == {
        'user'  => 'Hightower',
        'group' => 'admin',
        'mode'  => '0644'
      }
    end

    it "raises a data binding error if hiera cannot parse the yaml data" do
      expect do
        data_binder.find(request('invalid'))
      end.to raise_error(Puppet::DataBinding::LookupError)
    end
  end
end
