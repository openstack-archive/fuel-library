require 'spec_helper'

describe 'the corosync_nodes function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  let(:nodes) do
    [
        {
            "fqdn" => "node-1.domain.tld",
            "internal_address" => "192.168.0.5",
            "internal_netmask" => "255.255.255.0",
            "name" => "node-1",
            "public_address" => "172.16.0.6",
            "public_netmask" => "255.255.255.0",
            "role" => "primary-controller",
            "storage_address" => "192.168.1.1",
            "storage_netmask" => "255.255.255.0",
            "swift_zone" => "1",
            "uid" => "1",
            "user_node_name" => "Untitled (01:01)"
        },
        {
            "fqdn" => "node-2.domain.tld",
            "internal_address" => "192.168.0.6",
            "internal_netmask" => "255.255.255.0",
            "name" => "node-2",
            "public_address" => "172.16.0.7",
            "public_netmask" => "255.255.255.0",
            "role" => "primary-controller",
            "storage_address" => "192.168.1.2",
            "storage_netmask" => "255.255.255.0",
            "swift_zone" => "2",
            "uid" => "2",
            "user_node_name" => "Untitled (01:02)"
        }
    ]
  end

  let(:corosync_nodes_hash) do
    {
        "node-1.domain.tld" => {
            "ip" => "192.168.0.5",
            "id" => "1",
        },
        "node-2.domain.tld" => {
            "ip" => "192.168.0.6",
            "id" => "2",
        }
    }
  end

  it 'should exist' do
    expect(
        Puppet::Parser::Functions.function('corosync_nodes')
    ).to eq('function_corosync_nodes')
  end

  it 'should raise an error if there is less than 1 arguments' do
    expect {
      scope.function_corosync_nodes([])
    }.to raise_error
  end

  it 'should return corosync_nodes hash' do
    expect(
        scope.function_corosync_nodes([nodes])
    ).to eq corosync_nodes_hash
  end

end
