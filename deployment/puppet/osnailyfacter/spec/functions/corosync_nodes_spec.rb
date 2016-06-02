require 'spec_helper'

describe 'the corosync_nodes function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  let(:network_role) { 'mgmt/corosync' }
  let(:nodes) do
    {
        'node-1' => {
          'swift_zone' => '1',
          'uid' => '1',
          'fqdn' => 'node-1.domain.tld',
          'network_roles' => {
             'keystone/api' => '192.168.0.4',
             'neutron/api' => '192.168.0.4',
             'mgmt/database' => '192.168.0.4',
             'mgmt/corosync' => '192.168.0.5',
             'sahara/api' => '192.168.0.4',
             'heat/api' => '192.168.0.4',
             'ceilometer/api' => '192.168.0.4',
             'ex' => '10.109.1.4',
             'ceph/public' => '192.168.0.4',
             'ceph/radosgw' => '10.109.1.4',
             },
          },
        'node-2' => {
          'swift_zone' => '1',
          'uid' => '2',
          'fqdn' => 'node-2.domain.tld',
          'network_roles' => {
             'keystone/api' => '192.168.0.4',
             'neutron/api' => '192.168.0.4',
             'mgmt/database' => '192.168.0.4',
             'mgmt/corosync' => '192.168.0.6',
             'sahara/api' => '192.168.0.4',
             'heat/api' => '192.168.0.4',
             'ceilometer/api' => '192.168.0.4',
             'ex' => '10.109.1.4',
             'ceph/public' => '192.168.0.4',
             'ceph/radosgw' => '10.109.1.4',
             },
          },
        }
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
    }.to raise_error StandardError
  end

  it 'should return corosync_nodes hash' do
    expect(
        scope.function_corosync_nodes([nodes, network_role])
    ).to eq corosync_nodes_hash
  end

end
