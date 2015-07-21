require 'puppet'
require 'spec_helper'
require 'puppet/provider/neutron_port/neutron'

provider_class = Puppet::Type.type(:neutron_port).provider(:neutron)

describe provider_class do

  let :port_name do
    'port1'
  end

  let :port_attrs do
    {
      :name            => port_name,
      :ensure          => 'present',
      :admin_state_up  => 'True',
      :tenant_id       => '60f9544eb94c42a6b7e8e98c2be981b1',
      :network_name    => 'net1'
    }
  end

  let :resource do
    Puppet::Type::Neutron_port.new(port_attrs)
  end

  let :provider do
    provider_class.new(resource)
  end

  describe 'when creating a port' do

    it 'should call port-create with appropriate command line options' do
      provider.class.stubs(:get_tenant_id).returns(port_attrs[:tenant_id])

      output = 'Created a new port:
admin_state_up="True"
device_id=""
device_owner=""
fixed_ips="{\"subnet_id\": \"40af01ac-52c7-4235-bbcf-d9c02325ab5e\", \"ip_address\": \"192.168.0.39\"}"
id="5222573b-314d-45f9-b6bd-299288ba667a"
mac_address="fa:16:3e:45:3c:10"
name="port1"
network_id="98873773-aa34-4b87-af05-70903659246f"
security_groups="f1f0c3a3-9f2c-46b9-b2a5-b97d9a87bd7e"
status="ACTIVE"
tenant_id="60f9544eb94c42a6b7e8e98c2be981b1"'

      provider.expects(:auth_neutron).with('port-create',
                                           '--format=shell', "--name=#{port_attrs[:name]}",
                                           ["--tenant_id=#{port_attrs[:tenant_id]}"],
                                           port_attrs[:network_name]).returns(output)

      provider.create
    end
  end
end
