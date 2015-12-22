require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-swift.pp'

describe manifest do
  shared_examples 'catalog' do
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    # Determine if swift is used
    images_ceph = Noop.hiera_structure('storage/images_ceph', false)
    objects_ceph = Noop.hiera_structure('storage/objects_ceph', false)
    images_vcenter = Noop.hiera_structure('storage/images_vcenter', false)

    if images_ceph or objects_ceph or images_vcenter
      use_swift = false
    else
      use_swift = true
    end

    if use_swift and !Noop.hiera('external_lb', false)
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
    end
  end # end of shared_examples
    test_ubuntu_and_centos manifest
end

