require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/workloads_collector_remove.pp'

describe manifest do
  shared_examples 'catalog' do
    if Noop.hiera('external_lb', false)
      url = 'http://' + Noop.hiera('service_endpoint').to_s + ':35357'
      provider = 'http'
    else
      url = 'http://' + Noop.hiera('service_endpoint').to_s + ':10000/;csv'
      provider = nil
    end

    it {
      should contain_haproxy_backend_status('keystone-admin').with(
        :url      => url,
        :provider => provider
      )
    }
  end
  test_ubuntu_and_centos manifest
end
