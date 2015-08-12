require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-heat.pp'

describe manifest do
  shared_examples 'catalog' do
#    server_names = Noop.hiera_array('heat_names')
    public_ssl = Noop.hiera_structure('public_ssl')
    it 'should configure heat haproxy' do
      should contain_openstack__ha__haproxy_service('heat-api').with(
        'order'                  => '160',
        'listen_port'            => 8004,
        'require_service'        => 'heat-api',

        # common parameters
#        'internal_virtual_ip'    => internal_virtual_ip,
#        'ipaddresses'            => ipaddresses,
#        'public_virtual_ip'      => public_virtual_ip,
#        'server_names'           => server_names,
        'public'                 => 'true',
        'public_ssl'             => public_ssl,
        'require_service'        => 'heat-api',
        'haproxy_config_options' => {
          'option'           => ['httpchk', 'httplog','httpclose'],
          'timeout server' => '660s',
         },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      )

      should contain_openstack__ha__haproxy_service('heat-api-cfn').with(
        'order'           => '161',
        'listen_port'     => 8000,
        'require_service' => 'heat-api',
      )

      should contain_openstack__ha__haproxy_service('heat-api-cloudwatch').with(
        'order'           => '162',
        'listen_port'     => 8003,
        'require_service' => 'heat-api',
      )
    end
  end
  test_ubuntu_and_centos manifest
end

