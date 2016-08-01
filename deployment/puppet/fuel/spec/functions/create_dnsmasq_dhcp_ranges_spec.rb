require 'spec_helper'

describe 'create_dnsmasq_dhcp_ranges' do

  let(:admin_networks) do
    [
        {"id" => 1,
         "node_group_name" => nil,
         "node_group_id" => nil,
         "cluster_name" => nil,
         "cluster_id" => nil,
         "cidr" => "10.145.0.0/24",
         "gateway" => "10.145.0.2",
         "ip_ranges" => [["10.145.0.3", "10.145.0.250"]],
        },
        {"id" => 2,
         "node_group_name" => "default2",
         "node_group_id" => 22,
         "cluster_name" => "default2",
         "cluster_id" => 2,
         "cidr" => "10.144.0.0/24",
         "gateway" => "10.144.0.5",
         "ip_ranges" => [["10.144.0.10", "10.144.0.254"]],
        },
    ]
  end

  let(:facts) do
    {
      :interfaces => 'docker0,enp0s3,enp0s4,enp0s5,lo',
      :ipaddress_docker0 => '172.17.0.1',
      :ipaddress_enp0s3  => '10.145.0.2',
      :ipaddress_enp0s4  => '10.144.0.2',
    }
  end
  let(:catalog) do
    lambda { catalogue }
  end

  it 'refuses String' do
    is_expected.to run.with_params('foo').and_raise_error(Puppet::ParseError, /Should pass list of hashes as a parameter/)
  end

  it 'accepts empty data' do
    is_expected.to run.with_params([{}])
  end

  it 'can create dnsmasq dhcp ranges' do
    is_expected.to run.with_params(admin_networks)
    parameters = {
        :file_header=>"# Generated automatically by puppet\n# Environment: \n# Nodegroup: \n# IP range: [\"10.145.0.3\", \"10.145.0.250\"]",
        :listen_address=>'10.145.0.2',
        :dhcp_start_address=>"10.145.0.3",
        :dhcp_end_address=>"10.145.0.250",
        :dhcp_netmask=>"255.255.255.0",
        :dhcp_gateway=>"10.145.0.2",
    }
    expect(catalog).to contain_fuel__dnsmasq__dhcp_range('range_6be3c888').with parameters
    parameters = {
        :file_header=>"# Generated automatically by puppet\n# Environment: default2\n# Nodegroup: default2\n# IP range: [\"10.144.0.10\", \"10.144.0.254\"]",
        :listen_address=>'10.144.0.2',
        :dhcp_start_address=>"10.144.0.10",
        :dhcp_end_address=>"10.144.0.254",
        :dhcp_netmask=>"255.255.255.0",
        :dhcp_gateway=>"10.144.0.5",
    }
    expect(catalog).to contain_fuel__dnsmasq__dhcp_range('range_ff724fd0').with parameters
  end

end
