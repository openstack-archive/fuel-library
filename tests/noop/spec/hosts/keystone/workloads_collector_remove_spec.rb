# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd.yaml ubuntu
# RUN: neut_vlan.ironic.controller.yaml ubuntu
# RUN: neut_vlan.ironic.conductor.yaml ubuntu
# RUN: neut_vlan.compute.ssl.yaml ubuntu
# RUN: neut_vlan.compute.ssl.overridden.yaml ubuntu
# RUN: neut_vlan.compute.nossl.yaml ubuntu
# RUN: neut_vlan.cinder-block-device.compute.yaml ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl.yaml ubuntu
# RUN: neut_gre.generate_vms.yaml ubuntu
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
