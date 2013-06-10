require 'spec_helper'

describe Puppet::Type.type(:nova_floating).provider(:nova_manage) do

  let(:resource) { Puppet::Type.type(:nova_floating).new(:name => '192.168.1.1' ) }
  let(:provider) { resource.provider }

  describe "#create_by_name" do
    it "should create floating" do 
      provider.parse().should == ["192.168.1.1", nil]
    end
  end

  for net in ['10.0.0.1', '10.0.0.0/16'] do
    describe "#create #{net}" do
      it "should create floating for #{net}" do
        resource[:network]= net
        provider.expects(:nova_manage).with("floating", "create", net)
        provider.create()
      end
    end
    describe "#destroy #{net}" do
      it "should destroy floating for #{net}" do
        resource[:network]= net
        provider.expects(:nova_manage).with("floating", "delete", net)
        provider.destroy()
      end
    end
    describe "#check masklen #{net}" do
      it "should returns right values for #{net}" do 
        resource[:network]= net
        /([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})(\/([0-9]{1,2}))?/ =~ net
        provider.parse().should == [Regexp.last_match(1), Regexp.last_match(3)]
      end
    end
  end

end