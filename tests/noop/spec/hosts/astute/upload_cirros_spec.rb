# ROLE: primary-controller

require 'spec_helper'
require 'shared-examples'
manifest = 'astute/upload_cirros.pp'

describe manifest do
  shared_examples 'catalog' do

    storage_hash = Noop.hiera_hash 'storage'
    hw_disk_discard = Noop.puppet_function 'pick', storage_hash['disk_discard'], true

    let(:test_vm_images) { Noop.puppet_function 'flatten', [ Noop.hiera('test_vm_image') ] }
    let(:glance_images) { Noop.puppet_function 'generate_glance_images', test_vm_images }

    let(:extra_properties) {
      hw_disk_discard ? {'hw_scsi_model' => 'virtio-scsi', 'hw_disk_bus' => 'scsi'} : {}
    }

    it 'should contain upload_cirros class' do
      should contain_class('osnailyfacter::astute::upload_cirros')
    end

    it 'should wait for glance backends' do
      should contain_class('osnailyfacter::wait_for_glance_backends')
    end

    it 'should use glance_image provider' do
      glance_images.each do |name,test_vm_image|
        should contain_glance_image(name).with(
          :ensure => 'present',
          :container_format => test_vm_image['container_format'],
          :disk_format => test_vm_image['disk_format'],
          :is_public => test_vm_image['is_public'],
          :min_ram => test_vm_image['min_ram'],
          :source => test_vm_image['source'],
          :properties => test_vm_image['properties'].merge(extra_properties)
        )
      end
    end

    it 'should have explicit ordering between LB classes and images' do
      glance_images.each do |name,test_vm_image|
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[glance-api]", "Glance_image[#{name}]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[glance-registry]", "Glance_image[#{name}]")
      end
    end
  end

  test_ubuntu_and_centos manifest
end
