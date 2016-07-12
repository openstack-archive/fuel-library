# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'roles/controller.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:primary_controller) { Noop.hiera 'primary_controller' }
    let(:management_vip) { Noop.hiera('management_vip') }
    let(:service_endpoint)  { Noop.hiera('service_endpoint') }
    let(:nova_internal_protocol) { Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'nova', 'internal', 'protocol', 'http' }
    let(:nova_internal_endpoint) { Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'nova', 'internal', 'hostname', [service_endpoint, management_vip] }
    let(:external_lb) { Noop.hiera 'external_lb', false }

    let(:status_url) do
      if external_lb
        "#{nova_internal_protocol}://#{nova_internal_endpoint}:8774"
      else
        "http://#{management_vip}:10000/;csv"
      end
    end

    let(:status_provider) do
      if external_lb
        'http'
      else
        'haproxy'
      end
    end

    it 'should contain backend status calls on primary-controller only' do
      if primary_controller
        should contain_class('osnailyfacter::wait_for_nova_backends').with(
          :backends => ['nova-api'],
        )
        should contain_haproxy_backend_status('nova-api').with(
          :url      => status_url,
          :provider => status_provider
        )
      else
        should_not contain_class('osnailyfacter::wait_for_nova_backends')
      end
    end

    it 'should configure nova_flavor to manage flavor on primary-controller only' do
      if primary_controller
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[nova-api]", "Nova_flavor[m1.micro-flavor]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]","Nova_flavor[m1.micro-flavor]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]","Nova_flavor[m1.micro-flavor]")

        should contain_nova_flavor('m1.micro-flavor').with(
          :ram  => 64,
          :disk => 0,
          :vcpu => 1
        )
      else
        should_not contain_nova_flavor('m1.micro-flavor')
      end
    end

    it 'should install cirros image on primary-controler only' do
      if primary_controller
        should contain_package('cirros-testvm')
      else
        should_not contain_package('cirros-testvm')
      end
    end

    it 'should set vm.swappiness sysctl to 10' do
      should contain_sysctl('vm.swappiness').with(
        'val' => '10',
      )
    end
    it 'should make sure python-openstackclient package is installed' do
      should contain_package('python-openstackclient').with(
        'ensure' => 'installed',
      )
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

