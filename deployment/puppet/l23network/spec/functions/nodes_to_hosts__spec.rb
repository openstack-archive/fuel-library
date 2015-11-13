require 'spec_helper'

describe "nodes_to_hosts" do

  let :nodes do
  [
    { 'fqdn' => 'node-1.test.domain.local',
      'internal_address' => '10.109.1.39',
      'internal_netmask' => '255.255.255.224',
      'name' => 'node-1',
      'public_address' => '10.109.1.5',
      'public_netmask' => '255.255.255.224',
      'role' => 'primary-controller',
      'storage_address' => '10.109.1.69',
      'storage_netmask' => '255.255.255.224',
      'swift_zone' => '1',
      'uid' => '1',
      'user_node_name' => 'ctrl-001' },
    { 'fqdn' => 'node-2.test.domain.local',
      'name' => 'node-2',
      'role' => '__VOID__',
      'swift_zone' => '2',
      'uid' => '2',
      'user_node_name' => 'ctrl-002' },
  ]
  end

  let :expected_output do
    {
      nodes[0]['fqdn'] =>
        { :ip => nodes[0]['internal_address'],
          :host_aliases => [nodes[0]['name']] },
      nodes[1]['fqdn'] =>
        { :ensure => 'absent'},
    }
  end

  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params().and_return({}) }
  it { is_expected.to run.with_params([]).and_return({}) }
  it { is_expected.to run.with_params(nodes).and_return(expected_output) }
  it { is_expected.to run.with_params(true).and_raise_error(Puppet::ParseError, /Requires an array/) }

end
