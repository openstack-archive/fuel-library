require 'spec_helper'

describe Puppet::Type.type(:l23_stored_config) do
  before(:each) do
    puppet_debug_override()
  end

  it 'for ifconfig and addition routes' do
    catalog = Puppet::Resource::Catalog.new
    stored_config = Puppet::Type.type(:l23_stored_config).new(
        :name     => "eth1",
        :onboot   => "yes",
        :method   => "static",
        :ipaddr   => "169.254.1.3/24",
        :ipaddr_aliases => ["169.254.2.3/24", "169.254.3.3/24"],
        :provider => "lnx_ubuntu",
        :ensure   => :present
    )
    catalog.add_resource(stored_config)
    catalog.add_resource(Puppet::Type.type(:l3_route).new(
        :name        => "10.1.0.0/16",
        :destination => "10.1.0.0/16",
        :gateway     => "169.254.1.1",
        :metric      => 10,
        :ensure      => :present
    ))
    catalog.add_resource(Puppet::Type.type(:l3_route).new(
        :name        => "10.2.0.0/16",
        :destination => "10.2.0.0/16",
        :gateway     => "169.254.1.2",
        :ensure      => :present
    ))
    catalog.add_resource(Puppet::Type.type(:l3_route).new(
        :name        => "10.3.0.0/16",
        :destination => "10.3.0.0/16",
        :gateway     => "169.254.3.1",
        :ensure      => :present
    ))
    catalog.add_resource(Puppet::Type.type(:l3_route).new(
        :name        => "10.9.0.0/16",
        :destination => "10.9.0.0/16",
        :gateway     => "169.254.9.1",
        :ensure      => :present
    ))
    stored_config.generate()
    expect(stored_config[:routes]).to eq({
      "10.1.0.0/16" => {"gateway"=>"169.254.1.1", "destination"=>"10.1.0.0/16", "metric"=>"10"},
      "10.2.0.0/16" => {"gateway"=>"169.254.1.2", "destination"=>"10.2.0.0/16"},
      "10.3.0.0/16" => {"gateway"=>"169.254.3.1", "destination"=>"10.3.0.0/16"}
    })
  end
end
# vim: set ts=2 sw=2 et