# FIXME: neut_gre.generate_vms ubuntu
# FIXME: neut_vlan.ceph.ceil-compute.overridden_ssl ubuntu
# FIXME: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# FIXME: neut_vlan.ceph.compute-ephemeral-ceph ubuntu
# FIXME: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# FIXME: neut_vlan.cinder-block-device.compute ubuntu
# FIXME: neut_vlan.compute.nossl ubuntu
# FIXME: neut_vlan.compute.ssl ubuntu
# FIXME: neut_vlan.compute.ssl.overridden ubuntu
# FIXME: neut_vlan.ironic.conductor ubuntu
# FIXME: neut_vlan.ironic.controller ubuntu
# FIXME: neut_vlan_l3ha.ceph.ceil-ceph-osd ubuntu
# FIXME: neut_vlan_l3ha.ceph.ceil-compute ubuntu
# FIXME: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# FIXME: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# FIXME: neut_vlan_l3ha.ceph.ceil-primary-mongo ubuntu
# FIXME: neut_vxlan_dvr.murano.sahara-cinder ubuntu
# FIXME: neut_vxlan_dvr.murano.sahara-compute ubuntu
# FIXME: neut_vxlan_dvr.murano.sahara-controller ubuntu
# FIXME: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# FIXME: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/workloads_collector_remove.pp'

describe manifest do
  shared_examples 'catalog' do
    management_vip= Noop.hiera('management_vip')

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let(:admin_auth_protocol) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin',
        'protocol','http'
    }

    let(:admin_auth_address) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin',
        'hostname',[Noop.hiera('service_endpoint', ''), management_vip]
    }

    let(:admin_url) { "#{admin_auth_protocol}://#{admin_auth_address}:35357" }

    it {
      if Noop.hiera('external_lb', false)
        url = admin_url
        provider = 'http'
      else
        url = 'http://' + Noop.hiera('service_endpoint').to_s + ':10000/;csv'
        provider = Puppet::Type.type(:haproxy_backend_status).defaultprovider.name
      end
      should contain_haproxy_backend_status('keystone-admin').with(
        :url      => url,
        :provider => provider
      )
    }
  end
  test_ubuntu_and_centos manifest
end
