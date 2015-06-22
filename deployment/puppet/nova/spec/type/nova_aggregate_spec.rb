# run with: rspec spec/type/nova_aggregate_spec.rb

require 'spec_helper'


describe Puppet::Type.type(:nova_aggregate) do
  before :each do
    @provider_class = described_class.provide(:simple) do
      mk_resource_methods
      def create; end
      def delete; end
      def exists?; get(:ensure) != :absent; end
      def flush; end
      def self.instances; []; end
    end
  end

  it "should be able to create an instance" do
    described_class.new(:name => 'agg0').should_not be_nil
  end

  it "should be able to create an more complex instance" do
    expect(described_class.new(:name => 'agg0',
                        :availability_zone => 'myzone',
                        :metadata => "a=b, c=d",
                        :hosts => "host1")).to_not be_nil
  end

  it "should be able to create an more complex instance with multiple hosts" do
    expect(described_class.new(:name => 'agg0',
                        :availability_zone => 'myzone',
                        :metadata => "a=b, c=d",
                        :hosts => "host1, host2")).to_not be_nil
  end

  it "should be able to create a instance and have the default values" do
    c = described_class.new(:name => 'agg0')
    expect(c[:name]).to eq("agg0")
    expect(c[:availability_zone]).to eq( nil)
    expect(c[:metadata]).to eq(nil)
    expect(c[:hosts]).to eq(nil)
  end

  it "should return the given values" do
    c = described_class.new(:name => 'agg0',
                            :availability_zone => 'myzone',
                            :metadata => "  a  =  b  , c=  d  ",
                            :hosts => "  host1, host2    ")
    expect(c[:name]).to eq("agg0")
    expect(c[:availability_zone]).to eq("myzone")
    expect(c[:metadata]).to eq({"a" => "b", "c" => "d"})
    expect(c[:hosts]).to eq(["host1" , "host2"])
  end

  it "should return the given values" do
    c = described_class.new(:name => 'agg0',
                            :availability_zone => "",
                            :metadata => "",
                            :hosts => "")
    expect(c[:name]).to eq("agg0")
    expect(c[:availability_zone]).to eq("")
    expect(c[:metadata]).to eq({})
    expect(c[:hosts]).to eq([])
  end

end
