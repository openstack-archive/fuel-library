require 'puppet'
require 'spec_helper'

describe 'generate_vips' do

  before(:each) do
    puppet_debug_override
  end

  let(:network_metadata) do
    {'vips' => {
        'vrouter_pub' =>
            {'network_role' => 'public/vip',
             'node_roles' => %w(controller primary-controller),
             'namespace' => 'vrouter',
             'ipaddr' => '10.109.1.2',
             'vendor_specific' =>
                 {'iptables_rules' =>
                      {'ns_start' => ['iptables -t nat -A POSTROUTING -o <%INT%> -j MASQUERADE',
                                      'iptables -A INPUT -i <%INT%> -d <%IP%> -p tcp --dport 422 -j DROP',
                                      'iptables -A INPUT -i <%INT%> -d <%CIDR%> -p tcp --dport 555 -j DROP'
                      ],
                       'ns_stop' => ['iptables -t nat -D POSTROUTING -o <%INT%> -j MASQUERADE']}}},
        'management' =>
            {'network_role' => 'mgmt/vip',
             'node_roles' => %w(controller primary-controller),
             'namespace' => 'haproxy',
             'ipaddr' => '192.168.0.2'},
        'public' =>
            {'network_role' => 'public/vip',
             'node_roles' => %w(controller primary-controller),
             'namespace' => 'haproxy',
             'ipaddr' => '10.109.1.3'},
        'vrouter' =>
            {'network_role' => 'mgmt/vip',
             'node_roles' => %w(controller primary-controller),
             'namespace' => 'vrouter',
             'ipaddr' => '192.168.0.1'}
    }}
  end

  let (:network_scheme) do
    {
        'transformations' =>
            [],
        'roles' =>
            {'keystone/api' => 'br-mgmt',
             'neutron/api' => 'br-mgmt',
             'mgmt/database' => 'br-mgmt',
             'sahara/api' => 'br-mgmt',
             'heat/api' => 'br-mgmt',
             'ceilometer/api' => 'br-mgmt',
             'ex' => 'br-ex',
             'ceph/public' => 'br-mgmt',
             'mgmt/messaging' => 'br-mgmt',
             'management' => 'br-mgmt',
             'swift/api' => 'br-mgmt',
             'storage' => 'br-storage',
             'mgmt/corosync' => 'br-mgmt',
             'cinder/api' => 'br-mgmt',
             'public/vip' => 'br-ex',
             'swift/replication' => 'br-storage',
             'ceph/radosgw' => 'br-ex',
             'admin/pxe' => 'br-fw-admin',
             'mongo/db' => 'br-mgmt',
             'neutron/private' => 'br-prv',
             'neutron/floating' => 'br-floating',
             'fw-admin' => 'br-fw-admin',
             'glance/api' => 'br-mgmt',
             'mgmt/vip' => 'br-mgmt',
             'murano/api' => 'br-mgmt',
             'nova/api' => 'br-mgmt',
             'horizon' => 'br-mgmt',
             'nova/migration' => 'br-mgmt',
             'mgmt/memcache' => 'br-mgmt',
             'cinder/iscsi' => 'br-storage',
             'ceph/replication' => 'br-storage'},
        'interfaces' => {},
        'version' => '1.1',
        'provider' => 'lnx',
        'endpoints' =>
            {'br-fw-admin' => {'IP' => ['10.109.0.4/24']},
             'br-prv' => {'IP' => 'none'},
             'br-floating' => {'IP' => 'none'},
             'br-storage' => {'IP' => ['192.168.1.1/24']},
             'br-mgmt' => {'IP' => ['192.168.0.4/24']},
             'br-ex' => {'IP' => ['10.109.1.4/24'], 'gateway' => '10.109.1.1'}}}
  end

  let(:generated_data) do
    {
        'vrouter_pub' => {
            'ns' => 'vrouter',
            'base_veth' => 'v_vrouter_pub',
            'ns_veth' => 'b_vrouter_pub',
            'ip' => '10.109.1.2',
            'cidr_netmask' => '24',
            'bridge' => 'br-ex',
            'ns_iptables_start_rules' => 'iptables -t nat -A POSTROUTING -o b_vrouter_pub -j MASQUERADE; iptables -A INPUT -i b_vrouter_pub -d 10.109.1.2 -p tcp --dport 422 -j DROP; iptables -A INPUT -i b_vrouter_pub -d 10.109.1.2/24 -p tcp --dport 555 -j DROP',
            'ns_iptables_stop_rules' => 'iptables -t nat -D POSTROUTING -o b_vrouter_pub -j MASQUERADE',
            'colocation_before' => 'vrouter',
            'gateway_metric' => '0',
            'gateway' => '10.109.1.1',
        },
        'management' => {
            'ns' => 'haproxy',
            'base_veth' => 'v_management',
            'ns_veth' => 'b_management',
            'ip' => '192.168.0.2',
            'cidr_netmask' => '24',
            'bridge' => 'br-mgmt',
            'gateway_metric' => '0',
            'gateway' => 'none',
        },
        'public' => {
            'ns' => 'haproxy',
            'base_veth' => 'v_public',
            'ns_veth' => 'b_public',
            'ip' => '10.109.1.3',
            'cidr_netmask' => '24',
            'bridge' => 'br-ex',
            'gateway_metric' => '10',
            'gateway' => '10.109.1.1',
        },
        'vrouter' => {
            'ns' => 'vrouter',
            'base_veth' => 'v_vrouter',
            'ns_veth' => 'b_vrouter',
            'ip' => '192.168.0.1',
            'cidr_netmask' => '24',
            'bridge' => 'br-mgmt',
            'gateway_metric' => '0',
            'gateway' => 'none',
        }
    }
  end

  describe 'basic tests' do

    it 'should exist' do
      is_expected.not_to eq(nil)
    end

    it 'should require not empty network_metadata' do
      is_expected.to run.with_params('dd', {}, 'test_role').and_raise_error(Puppet::ParseError, /Missing or incorrect network_metadata in Hiera!/)
    end

    it 'should require not empty network_scheme' do
      is_expected.to run.with_params({}, 'bb', 'test_role').and_raise_error(Puppet::ParseError, /Missing or incorrect network_scheme /)
    end
  end

  describe 'when creating native types' do

    it 'should generate data for cluster::virtual_ip resources' do
      Puppet::Parser::Functions.autoloader.load :generate_vips
      puppet_scope = PuppetlabsSpec::PuppetInternals.scope

      puppet_scope.stubs(:function_prepare_network_config)
      puppet_scope.stubs(:function_get_network_role_property).with(['public/vip', 'interface']).returns('br-ex')
      puppet_scope.stubs(:function_get_network_role_property).with(['public/vip', 'netmask']).returns('255.255.255.0')
      puppet_scope.stubs(:function_get_network_role_property).with(['public/vip', 'gateway']).returns('10.109.1.1')
      puppet_scope.stubs(:function_get_network_role_property).with(['public/vip', 'gateway_metric']).returns('0')
      puppet_scope.stubs(:function_get_network_role_property).with(['mgmt/vip', 'interface']).returns('br-mgmt')
      puppet_scope.stubs(:function_get_network_role_property).with(['mgmt/vip', 'netmask']).returns('255.255.255.0')
      puppet_scope.stubs(:function_get_network_role_property).with(['mgmt/vip', 'gateway']).returns('')
      puppet_scope.stubs(:function_get_network_role_property).with(['mgmt/vip', 'gateway_metric']).returns('0')
      expect(
          puppet_scope.function_generate_vips [network_metadata, network_scheme, 'primary-controller']
      ).to eq generated_data
    end

  end

end
