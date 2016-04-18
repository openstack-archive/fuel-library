# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-haproxy/cluster-haproxy.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do
    let(:endpoints) do
      Noop.hiera_hash('network_scheme', {}).fetch('endpoints', {})
    end

    unless Noop.hiera('external_lb', false)

      it "should declare cluster::haproxy with correct other_networks" do
        expect(subject).to contain_class('cluster::haproxy').with(
          'other_networks' => Noop.puppet_function('direct_networks', endpoints),
        )
      end

      it "should setup rsyslog configuration for haproxy" do
        expect(subject).to contain_file('/etc/rsyslog.d/haproxy.conf')
      end

      if Noop.hiera('colocate_haproxy', true)
        it "should contain management vip colocation with haproxy" do
          expect(subject).to contain_pcmk_colocation('vip_management-with-haproxy').with(
            'first'  => 'clone_p_haproxy',
            'second' => 'vip__management',
          )
        end
        it "should contain public vip colocation with haproxy" do
          expect(subject).to contain_pcmk_colocation('vip_public-with-haproxy').with(
            'first'  => 'clone_p_haproxy',
            'second' => 'vip__public',
          )
        end
      end
    end

    external_lb = Noop.hiera('external_lb', false)
    # ceilometer config
    let(:ceilometer_nodes) { Noop.hiera_hash('ceilometer_nodes') }

    let(:ceilometer_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', ceilometer_nodes, 'heat/api'
    end

    let(:ceilometer_ipaddresses) do
      ceilometer_address_map.values
    end

    let(:ceilometer_server_names) do
      ceilometer_address_map.keys
    end

    use_ceilometer = Noop.hiera_structure('ceilometer/enabled', false)

    if use_ceilometer and !external_lb
      it "should properly configure ceilometer haproxy based on ssl" do
        public_ssl_ceilometer = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('ceilometer').with(
          'ipaddresses'            => ceilometer_ipaddresses,
          'server_names'           => ceilometer_server_names,
          'listen_port'            => 8777,
          'public'                 => true,
          'public_ssl'             => public_ssl_ceilometer,
          'require_service'        => 'ceilometer-api',
          'haproxy_config_options' => {
            'option'       => ['httplog', 'forceclose'],
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end
    end

    # cinder config
    let(:cinder_nodes) { Noop.hiera_hash('cinder_nodes') }

    let(:cinder_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', cinder_nodes, 'heat/api'
    end

    let(:cinder_ipaddresses) do
      cinder_address_map.values
    end

    let(:cinder_server_names) do
      cinder_address_map.keys
    end

    use_cinder = Noop.hiera_structure('cinder/enabled', true)

    if use_cinder and !external_lb
      it "should properly configure cinder haproxy based on ssl" do
        public_ssl_cinder = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('cinder-api').with(
          'ipaddresses'            => cinder_ipaddresses,
          'server_names'           => cinder_server_names,
          'listen_port'            => 8776,
          'public'                 => true,
          'public_ssl'             => public_ssl_cinder,
          'require_service'        => 'cinder-api',
          'haproxy_config_options' => {
            'option'       => ['httpchk', 'httplog', 'httpclose'],
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
        )
      end
    end

    # glance config
    let(:glance_nodes) { Noop.hiera_hash('glance_nodes') }

    let(:glance_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', glance_nodes, 'glance/api'
    end

    let(:glance_ipaddresses) do
      glance_address_map.values
    end

    let(:glance_server_names) do
      glance_address_map.keys
    end

    let(:glance_public_virtual_ip) { Noop.hiera('public_vip') }
    let(:glance_internal_virtual_ip) { Noop.hiera('management_vip') }

    let(:glance_public_ssl_hash) { Noop.hiera_hash('public_ssl', {}) }
    let(:glance_ssl_hash) { Noop.hiera_hash('use_ssl', {}) }
    let(:glance_public_ssl) { Noop.puppet_function 'get_ssl_property',glance_ssl_hash,glance_public_ssl_hash,'glance','public','usage',false }

    unless external_lb
      it 'should configure glance haproxy' do
        should contain_openstack__ha__haproxy_service('glance-api').with(
          'order'                  => '080',
          'listen_port'            => 9292,
          'require_service'        => 'glance-api',

          # common parameters
          'internal_virtual_ip'    => glance_internal_virtual_ip,
          'ipaddresses'            => glance_ipaddresses,
          'public_virtual_ip'      => glance_public_virtual_ip,
          'server_names'           => glance_server_names,
          'public'                 => 'true',
          'public_ssl'             => glance_public_ssl,
          'require_service'        => 'glance-api',
          'haproxy_config_options' => {
            'option'         => ['httpchk GET /healthcheck', 'httplog', 'httpclose'],
            'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            'timeout server' => '11m',
           },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3'
        )

        should contain_openstack__ha__haproxy_service('glance-glare').with(
          'listen_port'            => 9494,
          'require_service'        => 'glance-glare',

          # common parameters
          'internal_virtual_ip'    => glance_internal_virtual_ip,
          'ipaddresses'            => glance_ipaddresses,
          'public_virtual_ip'      => glance_public_virtual_ip,
          'server_names'           => glance_server_names,
          'public'                 => 'true',
          'public_ssl'             => glance_public_ssl,
          'require_service'        => 'glance-glare',
          'haproxy_config_options' => {
            'option'         => ['httpchk /versions', 'httplog', 'httpclose'],
            'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            'timeout server' => '11m',
           },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3'
        )

        should contain_openstack__ha__haproxy_service('glance-registry').with(
          'listen_port'     => 9191,
          'haproxy_config_options' => {
            'timeout server' => '11m',
           },
        )
      end
    end

    # heat config
    let(:heat_nodes) { Noop.hiera_hash('heat_nodes') }

    let(:heat_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', heat_nodes, 'heat/api'
    end

    let(:heat_ipaddresses) do
      heat_address_map.values
    end

    let(:heat_server_names) do
      heat_address_map.keys
    end

    let(:heat_public_virtual_ip) { Noop.hiera('public_vip') }
    let(:heat_internal_virtual_ip) { Noop.hiera('management_vip') }
    let(:heat_public_ssl_hash) { Noop.hiera_hash('public_ssl', {}) }
    let(:heat_ssl_hash) { Noop.hiera_hash('use_ssl', {}) }
    let(:heat_public_ssl) { Noop.puppet_function 'get_ssl_property',heat_ssl_hash,heat_public_ssl_hash,'heat','public','usage',false }

    unless external_lb
      it 'should configure heat haproxy' do
        should contain_openstack__ha__haproxy_service('heat-api').with(
          'listen_port'            => 8004,
          'require_service'        => 'heat-api',
          # common parameters
          'internal_virtual_ip'    => heat_internal_virtual_ip,
          'ipaddresses'            => heat_ipaddresses,
          'public_virtual_ip'      => heat_public_virtual_ip,
          'server_names'           => heat_server_names,
          'public'                 => 'true',
          'public_ssl'             => heat_public_ssl,
          'require_service'        => 'heat-api',
          'haproxy_config_options' => {
            'option'         => ['httpchk', 'httplog', 'httpclose'],
            'timeout server' => '660s',
            'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
           },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3'
        )

        should contain_openstack__ha__haproxy_service('heat-api-cfn').with(
          'listen_port'     => 8000,
          'require_service' => 'heat-api'
        )

        should contain_openstack__ha__haproxy_service('heat-api-cloudwatch').with(
          'listen_port'     => 8003,
          'require_service' => 'heat-api'
        )
      end
    end

    # horizon config
    let(:horizon_nodes) { Noop.hiera_hash('horizon_nodes') }
    let(:horizon_public_ssl_hash) { Noop.hiera_hash('public_ssl', {}) }
    let(:horizon_ssl_hash) { Noop.hiera_hash('use_ssl', {}) }
    let(:horizon_public_ssl) { Noop.puppet_function 'get_ssl_property',horizon_ssl_hash,horizon_public_ssl_hash,'horizon','public','usage',false }

    let(:horizon_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', horizon_nodes, 'heat/api'
    end

    let(:horizon_ipaddresses) do
      horizon_address_map.values
    end

    let(:horizon_server_names) do
      horizon_address_map.keys
    end

    unless external_lb
      it "should properly configure horizon haproxy based on ssl" do
        if horizon_public_ssl
          # http horizon should redirect to ssl horizon
          should contain_openstack__ha__haproxy_service('horizon').with(
            'server_names'           => nil,
            'ipaddresses'            => nil,
            'haproxy_config_options' => {
              'redirect' => 'scheme https if !{ ssl_fc }'
            }
          )
          should_not contain_haproxy__balancermember('horizon')
          should contain_openstack__ha__haproxy_service('horizon-ssl').with(
            'order'                  => '017',
            'ipaddresses'            => horizon_ipaddresses,
            'server_names'           => horizon_server_names,
            'listen_port'            => 443,
            'balancermember_port'    => 80,
            'public_ssl'             => horizon_public_ssl,
            'haproxy_config_options' => {
              'option'      => ['forwardfor', 'httpchk', 'httpclose', 'httplog'],
              'stick-table' => 'type ip size 200k expire 30m',
              'stick'       => 'on src',
              'balance'     => 'source',
              'timeout'     => ['client 3h', 'server 3h'],
              'mode'        => 'http',
              'reqadd'      => 'X-Forwarded-Proto:\ https',
            },
            'balancermember_options' => 'weight 1 check'
          )
          should contain_haproxy__balancermember('horizon-ssl')
        else
          # http horizon only
          should contain_openstack__ha__haproxy_service('horizon').with(
            'ipaddresses'            => horizon_ipaddresses,
            'server_names'           => horizon_server_names,
            'haproxy_config_options' => {
              'balance' => 'source',
              'capture' => 'cookie vgnvisitor= len 32',
              'cookie'  => 'SERVERID insert indirect nocache',
              'mode'    => 'http',
              'option'  => [ 'forwardfor', 'httpchk', 'httpclose', 'httplog' ],
              'rspidel' => '^Set-cookie:\ IP=',
              'timeout' => [ 'client 3h', 'server 3h' ]
            }
          )
          should contain_haproxy__balancermember('horizon')
          should_not contain_openstack__ha__haproxy_service('horizon-ssl')
          should_not contain_haproxy__balancermember('horizon-ssl')
        end
      end
    end


    # ironic config
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'
    if ironic_enabled
      let(:ironic_api_nodes) { Noop.hiera_hash('ironic_api_nodes') }

      let(:ironic_address_map) do
        Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', ironic_api_nodes, 'ironic/api'
      end

      let(:ironic_ipaddresses) do
        ironic_address_map.values
      end

      let(:ironic_server_names) do
        ironic_address_map.keys
      end

      use_ironic = Noop.hiera_structure('ironic/enabled', true)
      let(:ironic_baremetal_virtual_ip) { Noop.hiera_structure 'network_metadata/vips/baremetal/ipaddr' }
      let(:ironic_public_ssl) { Noop.hiera_structure('public_ssl/services', false) }

      if use_ironic and !external_lb
        it "should properly configure ironic haproxy based on ssl" do
          should contain_openstack__ha__haproxy_service('ironic').with(
            'ipaddresses'            => ironic_ipaddresses,
            'server_names'           => ironic_server_names,
            'listen_port'            => 6385,
            'public'                 => true,
            'public_ssl'             => ironic_public_ssl,
            'haproxy_config_options' => {
              'option'       => ['httpchk GET /', 'httplog', 'httpclose'],
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },

          )
        end
        it "should properly configure ironic haproxy on baremetal vip" do
          should contain_openstack__ha__haproxy_service('ironic-baremetal').with(
            'ipaddresses'            => ironic_ipaddresses,
            'server_names'           => ironic_server_names,
            'listen_port'            => 6385,
            'public_virtual_ip'      => false,
            'internal_virtual_ip'    => ironic_baremetal_virtual_ip,
            'haproxy_config_options' => {
              'option'       => ['httpchk GET /', 'httplog', 'httpclose'],
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },

          )
        end
      end

      it 'should declare openstack::ha::ironic class with baremetal_virtual_ip' do
        should contain_class('openstack::ha::ironic').with(
          'baremetal_virtual_ip' => ironic_baremetal_virtual_ip,
        )
      end
    end

    # keystone conf
    let(:keystone_nodes) { Noop.hiera_hash('keystone_nodes') }

    let(:keystone_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', keystone_nodes, 'heat/api'
    end

    let(:keystone_ipaddresses) do
      keystone_address_map.values
    end

    let(:keystone_server_names) do
      keystone_address_map.keys
    end

    let(:keystone_public_ssl) { Noop.hiera_structure('public_ssl/services', false) }

    use_keystone = Noop.hiera_structure('keystone/enabled', true)

    if use_keystone and !external_lb
      it "should properly configure keystone haproxy based on ssl" do
        should contain_openstack__ha__haproxy_service('keystone-1').with(
          'ipaddresses'            => keystone_ipaddresses,
          'server_names'           => keystone_server_names,
          'listen_port'            => 5000,
          'public'                 => true,
          'public_ssl'             => keystone_public_ssl,
          'haproxy_config_options' => {
            'option'       => ['httpchk GET /v3', 'httplog', 'httpclose', 'forwardfor'],
            'stick'          => ['on src'],
            'stick-table'    => ['type ip size 200k expire 2m'],
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end
      it "should properly configure keystone haproxy admin without public" do
        should contain_openstack__ha__haproxy_service('keystone-2').with(
          'order'                  => '030',
          'ipaddresses'            => keystone_ipaddresses,
          'server_names'           => keystone_server_names,
          'listen_port'            => 35357,
          'public'                 => false,
          'haproxy_config_options' => {
            'option'       => ['httpchk GET /v3', 'httplog', 'httpclose', 'forwardfor'],
            'stick'          => ['on src'],
            'stick-table'    => ['type ip size 200k expire 2m'],
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end
    end

    # murano config
    let(:murano_nodes) { Noop.hiera_hash('murano_nodes') }

    let(:murano_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', murano_nodes, 'heat/api'
    end

    let(:murano_ipaddresses) do
      murano_address_map.values
    end

    let(:murano_server_names) do
      murano_address_map.keys
    end

    let(:murano_public_ssl) { Noop.hiera_structure('public_ssl/services', false) }

    use_murano = Noop.hiera_structure('murano/enabled', false)
    use_cfapi_murano = Noop.hiera_structure('murano-cfapi/enabled', false)

    if use_murano and !external_lb
      it "should properly configure murano haproxy based on ssl" do
        should contain_openstack__ha__haproxy_service('murano-api').with(
          'order'                  => '190',
          'ipaddresses'            => murano_ipaddresses,
          'server_names'           => murano_server_names,
          'listen_port'            => 8082,
          'public'                 => true,
          'public_ssl'             => murano_public_ssl,
          'require_service'        => 'murano_api',
          'haproxy_config_options' => {
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end

      if use_cfapi_murano
        it "should properly configure murano-cfapi haproxy based on ssl" do
          should contain_openstack__ha__haproxy_service('murano-cfapi').with(
            'order'                  => '192',
            'ipaddresses'            => murano_ipaddresses,
            'server_names'           => murano_server_names,
            'listen_port'            => 8083,
            'public'                 => true,
            'public_ssl'             => murano_public_ssl,
            'require_service'        => 'murano_cfapi',
            'haproxy_config_options' => {
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },
          )
        end
      end

      it "should properly configure murano rabbitmq haproxy" do
        should contain_openstack__ha__haproxy_service('murano_rabbitmq').with(
          'order'                  => '191',
          'ipaddresses'            => murano_ipaddresses,
          'server_names'           => murano_server_names,
          'listen_port'            => 55572,
          'internal'               => false,
          'haproxy_config_options' => {
            'option'         => ['tcpka'],
            'timeout client' => '48h',
            'timeout server' => '48h',
            'balance'        => 'roundrobin',
            'mode'           => 'tcp',
          },
        )
      end
    end

    # mysql conf
    mysql_hash = Noop.hiera_hash('mysql')
    use_mysql = Noop.puppet_function 'pick', mysql_hash['enabled'], true
    custom_mysql_setup_class = Noop.hiera('custom_mysql_setup_class', 'galera')

    if !external_lb and use_mysql and
      ['galera', 'percona', 'percona_packages'].include? custom_mysql_setup_class
      let(:database_nodes) { Noop.hiera_hash('database_nodes') }
      let(:db_address_map) { Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', database_nodes, 'mgmt/database' }
      let(:mysql_ipaddresses) { Noop.hiera_array('mysqld_ipaddresses', db_address_map.values) }
      let(:mysql_server_names) { Noop.hiera_array('mysqld_names', db_address_map.keys) }
      let(:mysql_public_virtual_ip) { Noop.hiera('public_vip') }
      let(:mysql_internal_virtual_ip) { Noop.hiera('database_vip', Noop.hiera('management_vip')) }
      let(:primary_controller) { Noop.hiera('primary_controller') }

      it 'should contain mysql ha class' do
        should contain_class('openstack::ha::mysqld').with(
          'internal_virtual_ip'   => mysql_internal_virtual_ip,
          'ipaddresses'           => mysql_ipaddresses,
          'public_virtual_ip'     => mysql_public_virtual_ip,
          'server_names'          => mysql_server_names,
          'is_primary_controller' => primary_controller,
        )
      end

      it 'should properly configure database haproxy' do
        should contain_openstack__ha__haproxy_service('mysqld').with(
          'listen_port'            => 3306,
          'balancermember_port'    => 3307,
          'define_backups'         => true,
          'haproxy_config_options' => {
            'hash-type'      => 'consistent',
            'option'         => ['httpchk', 'tcplog','clitcpka','srvtcpka'],
            'balance'        => 'source',
            'mode'           => 'tcp',
            'timeout server' => '28801s',
            'timeout client' => '28801s'
          },
          'balancermember_options' =>
            'check port 49000 inter 20s fastinter 2s downinter 2s rise 3 fall 3',
        )
      end
    end

    # neutron conf
    let(:neutron_nodes) { Noop.hiera_hash('neutron_nodes') }

    let(:neutron_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', neutron_nodes, 'heat/api'
    end

    let(:neutron_ipaddresses) do
      neutron_address_map.values
    end

    let(:neutron_server_names) do
      neutron_address_map.keys
    end

    let(:neutron_public_ssl) { Noop.hiera_structure('public_ssl/services', false) }

    use_neutron = Noop.hiera('use_neutron', false)

    if use_neutron and !external_lb
      it "should properly configure neutron haproxy based on ssl" do
        should contain_openstack__ha__haproxy_service('neutron').with(
          'order'                  => '085',
          'ipaddresses'            => neutron_ipaddresses,
          'server_names'           => neutron_server_names,
          'listen_port'            => 9696,
          'public'                 => true,
          'public_ssl'             => neutron_public_ssl,
          'haproxy_config_options' => {
            'option'       => ['httpchk', 'httplog', 'httpclose'],
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
        )
      end
    end

    # nova config
    let(:nova_api_nodes) { Noop.hiera_hash('nova_api_nodes') }

    let(:nova_api_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', nova_api_nodes, 'heat/api'
    end

    let(:nova_ipaddresses) do
      nova_api_address_map.values
    end

    let(:nova_server_names) do
      nova_api_address_map.keys
    end

    let(:nova_public_ssl) { Noop.hiera_structure('public_ssl/services', false) }

    use_nova = Noop.hiera_structure('nova/enabled', true)

    if use_nova and !external_lb
      it "should properly configure nova haproxy based on ssl" do
        should contain_openstack__ha__haproxy_service('nova-api').with(
          'order'                  => '040',
          'ipaddresses'            => nova_ipaddresses,
          'server_names'           => nova_server_names,
          'listen_port'            => 8774,
          'public'                 => true,
          'public_ssl'             => nova_public_ssl,
          'require_service'        => 'nova-api',
          'haproxy_config_options' => {
            'timeout server' => '600s',
            'option'         => ['httpchk', 'httplog', 'httpclose'],
            'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
        )
      end
      it "should properly configure nova-metadata-api haproxy" do
        should contain_openstack__ha__haproxy_service('nova-metadata-api').with(
          'order'                  => '050',
          'ipaddresses'            => nova_ipaddresses,
          'server_names'           => nova_server_names,
          'listen_port'            => 8775,
          'haproxy_config_options' => {
            'option'         => ['httpchk', 'httplog', 'httpclose'],
          },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
        )
      end
      it "should properly configure nova-novncproxy haproxy based on ssl" do
        should contain_openstack__ha__haproxy_service('nova-novncproxy').with(
          'order'                  => '170',
          'ipaddresses'            => nova_ipaddresses,
          'server_names'           => nova_server_names,
          'listen_port'            => 6080,
          'public'                 => true,
          'public_ssl'             => nova_public_ssl,
          'internal'               => false,
          'require_service'        => 'nova-vncproxy',
          'haproxy_config_options' => {
            'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end
    end

    # radosgw config
    images_ceph = Noop.hiera_structure 'storage/images_ceph'
    objects_ceph = Noop.hiera_structure 'storage/objects_ceph'

    if images_ceph and objects_ceph and !external_lb

      let(:rgw_nodes) { Noop.hiera_hash('ceph_rgw_nodes') }

      let(:rgw_address_map) do
        Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', rgw_nodes, 'heat/api'
      end

      let(:radosgw_ipaddresses) do
        rgw_address_map.values
      end

      let(:radosgw_server_names) do
        rgw_address_map.keys
      end

      let(:radosgw_public_ssl) { Noop.hiera_structure('public_ssl/services', false) }

      if ironic_enabled
        it 'should declare ::openstack::ha::radosgw class with baremetal_virtual_ip' do
          should contain_class('openstack::ha::radosgw').with(
            'baremetal_virtual_ip' => ironic_baremetal_virtual_ip,
          )
        end

        it "should properly configure radosgw haproxy based on ssl" do
          should contain_openstack__ha__haproxy_service('object-storage').with(
            'ipaddresses'            => radosgw_ipaddresses,
            'server_names'           => radosgw_server_names,
            'listen_port'            => 8080,
            'balancermember_port'    => 6780,
            'public'                 => true,
            'public_ssl'             => radosgw_public_ssl,
            'require_service'        => 'radosgw-api',
            'haproxy_config_options' => {
              'option'       => ['httplog', 'httpchk GET /'],
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },
          )
        end

        it 'should declare openstack::ha::haproxy_service with name radosgw-baremetal' do
          should contain_openstack__ha__haproxy_service('object-storage-baremetal').with(
            'ipaddresses'            => radosgw_ipaddresses,
            'server_names'           => radosgw_server_names,
            'listen_port'            => 8080,
            'balancermember_port'    => 6780,
            'public_virtual_ip'      => false,
            'internal_virtual_ip'    => ironic_baremetal_virtual_ip,
            'haproxy_config_options' => {
              'option'       => ['httplog', 'httpchk GET /'],
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },
          )
        end
      end
    end

    # sahara config
    let(:sahara_nodes) { Noop.hiera_hash('sahara_nodes') }

    let(:sahara_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', sahara_nodes, 'heat/api'
    end

    let(:sahara_ipaddresses) do
      sahara_address_map.values
    end

    let(:sahara_server_names) do
      sahara_address_map.keys
    end

    let(:sahara_public_ssl) { Noop.hiera_structure('public_ssl/services', false) }

    use_sahara = Noop.hiera_structure('sahara/enabled', false)

    if use_sahara and !external_lb

      it "should properly configure sahara haproxy based on ssl" do
        should contain_openstack__ha__haproxy_service('sahara').with(
          'order'                  => '150',
          'ipaddresses'            => sahara_ipaddresses,
          'server_names'           => sahara_server_names,
          'listen_port'            => 8386,
          'public'                 => true,
          'public_ssl'             => sahara_public_ssl,
          'require_service'        => 'sahara-api',
          'haproxy_config_options' => {
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end
    end

    # stats config
    management_vip = Noop.hiera 'management_vip'
    database_vip = Noop.hiera 'database_vip'
    database_vip ||= management_vip

    unless external_lb
      it "should contain stats fragment and listen #{[management_vip, database_vip].uniq.inspect}" do
        [management_vip, database_vip].each do |ip|
          should contain_concat__fragment('haproxy-stats_listen_block').with_content(
            %r{\n\s*bind\s+#{ip}:10000\s*$\n}
          )
        end
      end
    end

    # swift config
    images_vcenter = Noop.hiera_structure('storage/images_vcenter', false)

    if images_ceph or objects_ceph or images_vcenter
      use_swift = false
    else
      use_swift = true
    end

    let (:bind_to_one) {
      internal_virtual_ip = Noop.hiera_structure 'network_metadata/vips/management/ipaddr'
      api_net = Noop.puppet_function 'get_network_role_property', 'swift/api', 'network'
      Noop.puppet_function 'has_ip_in_network', internal_virtual_ip, api_net
    }

    let (:bm_options) {
      bm_opt_tail = 'inter 15s fastinter 2s downinter 8s rise 3 fall 3'
      bind_to_one ? "check #{bm_opt_tail}" : "check port 49001 #{bm_opt_tail}"
    }

    let (:http_check) {
      bind_to_one ? 'httpchk HEAD /healthcheck HTTP/1.0' : 'httpchk'
    }

    let(:haproxy_config_opts) do
      {
        'option'       => [http_check, 'httplog', 'httpclose', 'tcp-smart-accept', 'tcp-smart-connect'],
        'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
      }
    end

    let (:swift_public_ssl) { Noop.hiera_structure('public_ssl/services', false) }
    if use_swift and !Noop.hiera('external_lb', false)

      it "should declare openstack::ha:swift class with valid params" do
        should contain_class('openstack::ha::swift').with(
          'bind_to_one' => bind_to_one,
        )
      end

      it "should properly configure swift haproxy based on ssl" do
        should contain_openstack__ha__haproxy_service('object-storage').with(
          'order'                  => '130',
          'listen_port'            => 8080,
          'public'                 => true,
          'public_ssl'             => swift_public_ssl,
          'haproxy_config_options' => haproxy_config_opts,
          'balancermember_options' => bm_options,
        )
      end

      if ironic_enabled

        it 'should declare ::openstack::ha::swift class with baremetal_virtual_ip' do
          should contain_class('openstack::ha::swift').with(
            'baremetal_virtual_ip' => ironic_baremetal_virtual_ip,
          )
        end

        it 'should declare openstack::ha::haproxy_service with name swift-baremetal' do
          should contain_openstack__ha__haproxy_service('object-storage-baremetal').with(
            'order'                  => '135',
            'listen_port'            => 8080,
            'public_virtual_ip'      => false,
            'internal_virtual_ip'    => ironic_baremetal_virtual_ip,
            'haproxy_config_options' => haproxy_config_opts,
            'balancermember_options' => bm_options,
          )
        end
      end
    end
  end

  test_ubuntu_and_centos manifest
end
