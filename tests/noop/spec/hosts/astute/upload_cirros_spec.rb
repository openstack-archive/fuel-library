# ROLE: primary-controller

require 'spec_helper'
require 'shared-examples'
manifest = 'astute/upload_cirros.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:test_vm_image) { Noop.hiera_hash('test_vm_image') }
    it 'should contain upload_cirros class' do
      should contain_class('osnailyfacter::astute::upload_cirros')
    end

    it 'should wait for glance backends' do
      should contain_class('osnailyfacter::wait_for_glance_backends')
    end

    it 'should use glance_image provider' do
      should contain_glance_image(test_vm_image['img_name']).with(
        :ensure => 'present',
        :container_format => test_vm_image['container_format'],
        :disk_format => test_vm_image['disk_format'],
        :is_public => test_vm_image['public'],
        :min_ram => test_vm_image['min_ram'],
        :source => test_vm_image['img_path']
      )
    end

    it 'should have explicit ordering between LB classes and images' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[glance-api]",
                                                      "Glance_image['TestVM']")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[glance-registry]",
                                                      "Glance_image['TestVM']")
    end
  end

  test_ubuntu_and_centos manifest
end
