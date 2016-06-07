require 'spec_helper'

describe 'corosync_nodes' do
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
    is_expected.not_to be_nil
  end

  it 'should raise an error if there is less than 1 arguments' do
    is_expected.to run.with_params([]).and_raise_error(Puppet::ParseError)
  end

  it 'should return corosync_nodes hash' do
    is_expected.to run.with_params(nodes, network_role).and_return(corosync_nodes_hash)
  end

end
