require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-radosgw.pp'

describe manifest do
  shared_examples 'catalog' do
    images_ceph = Noop.hiera_structure 'storage/images_ceph'
    objects_ceph = Noop.hiera_structure 'storage/objects_ceph'
    if images_ceph and objects_ceph and !Noop.hiera('external_lb', false)
      ironic_enabled = Noop.hiera_structure 'ironic/enabled'
      if ironic_enabled
        baremetal_virtual_ip = Noop.hiera_structure 'network_metadata/vips/baremetal/ipaddr'

        it 'should declare ::openstack::ha::radosgw class with baremetal_virtual_ip' do
          should contain_class('openstack::ha::radosgw').with(
            'baremetal_virtual_ip' => baremetal_virtual_ip,
          )
        end

        it "should properly configure radosgw haproxy based on ssl" do
          public_ssl_radosgw = Noop.hiera_structure('public_ssl/services', false)
          should contain_openstack__ha__haproxy_service('radosgw').with(
            'order'                  => '130',
            'listen_port'            => 8080,
            'balancermember_port'    => 6780,
            'public'                 => true,
            'public_ssl'             => public_ssl_radosgw,
            'require_service'        => 'radosgw-api',
            'haproxy_config_options' => {
              'option'       => ['httplog', 'httpchk GET /'],
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },
          )
        end

        it 'should declare openstack::ha::haproxy_service with name radosgw-baremetal' do
            should contain_openstack__ha__haproxy_service('radosgw-baremetal').with(
              'order'                  => '135',
              'listen_port'            => 8080,
              'balancermember_port'    => 6780,
              'public_virtual_ip'      => false,
              'internal_virtual_ip'    => baremetal_virtual_ip,
              'haproxy_config_options' => {
                'option'       => ['httplog', 'httpchk GET /'],
                'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
              },
            )
        end
      end
    end
  end # end of shared_examples
  test_ubuntu_and_centos manifest
end

