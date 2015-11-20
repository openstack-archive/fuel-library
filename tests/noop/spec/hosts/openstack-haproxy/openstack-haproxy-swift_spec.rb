require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-swift.pp'

describe manifest do
  shared_examples 'catalog' do
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'
    ceilometer_enabled = Noop.hiera_structure 'ceilometer/enabled'
    amqp_hosts = Noop.hiera 'amqp_hosts'
    amqp_port = Noop.hiera 'amqp_port'
    let (:amqp_ipaddresses) do
      amqp_hosts.split(', ').each do |host|
        host.slice! ":#{amqp_port}"
      end
    end

    # Determine if swift is used
    images_ceph = Noop.hiera_structure('storage/images_ceph', false)
    objects_ceph = Noop.hiera_structure('storage/objects_ceph', false)
    images_vcenter = Noop.hiera_structure('storage/images_vcenter', false)

    if images_ceph or objects_ceph or images_vcenter
      use_swift = false
    else
      use_swift = true
    end

    if use_swift
      it "should properly configure swift haproxy based on ssl" do
        public_ssl_swift = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('swift').with(
          'order'                  => '120',
          'listen_port'            => 8080,
          'public'                 => true,
          'public_ssl'             => public_ssl_swift,
          'haproxy_config_options' => {
            'option'       => ['httpchk', 'httplog', 'httpclose'],
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
          'balancermember_options' => 'check port 49001 inter 15s fastinter 2s downinter 8s rise 3 fall 3',
        )
      end


      if ironic_enabled
        baremetal_virtual_ip = Noop.hiera_structure 'network_metadata/vips/baremetal/ipaddr'
  
        it 'should declare ::openstack::ha::swift class with baremetal_virtual_ip' do
          should contain_class('openstack::ha::swift').with(
            'baremetal_virtual_ip' => baremetal_virtual_ip,
          )
        end
        it 'should declare openstack::ha::haproxy_service with name swift-baremetal' do
          should contain_openstack__ha__haproxy_service('swift-baremetal').with(
            'order'                  => '125',
            'listen_port'            => 8080,
            'public_virtual_ip'      => false,
            'internal_virtual_ip'    => baremetal_virtual_ip,
            'haproxy_config_options' => {
             'option'        => ['httpchk', 'httplog', 'httpclose'],
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },
            'balancermember_options' => 'check port 49001 inter 15s fastinter 2s downinter 8s rise 3 fall 3',
          )
        end
      end
      if ceilometer_enabled
        it 'should declare ::openstack::ha::swift class with amqp_swift_proxy_enabled enabled' do
          should contain_class('openstack::ha::swift').with(
            'amqp_swift_proxy_enabled' => true,
          )
        end

        it 'should declare openstack::ha::haproxy_service with name swift_proxy_rabbitmq' do
            should contain_openstack__ha__haproxy_service('swift_proxy_rabbitmq').with(
              'order'                  => '121',
              'listen_port'            => 5673,
              'define_backups'         => true,
              'internal'               => true,
              'ipaddresses'            => amqp_ipaddresses,
              'server_names'           => amqp_ipaddresses,
              'haproxy_config_options' => {
                'option'         => ['tcpka'],
                'timeout client' => '48h',
                'timeout server' => '48h',
                'balance'        => 'roundrobin',
                'mode'           => 'tcp'
              },
              'balancermember_options' => 'check inter 5000 rise 2 fall 3',
            )
        end
      end
    end
  end # end of shared_examples
    test_ubuntu_and_centos manifest
end

