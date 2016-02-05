require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/workloads_collector_remove.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do
    management_vip= task.hiera('management_vip')

    let(:ssl_hash) { task.hiera_hash 'use_ssl', {} }

    let(:admin_auth_protocol) {
      task.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin',
        'protocol','http'
    }

    let(:admin_auth_address) {
      task.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin',
        'hostname',[task.hiera('service_endpoint', ''), management_vip]
    }

    let(:admin_url) { "#{admin_auth_protocol}://#{admin_auth_address}:35357" }

    it {
      if task.hiera('external_lb', false)
        url = admin_url
        provider = 'http'
      else
        url = 'http://' + task.hiera('service_endpoint').to_s + ':10000/;csv'
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
