# ROLE: cinder-vmware

require 'spec_helper'
require 'shared-examples'
manifest = 'vmware/cinder-vmware.pp'

describe manifest do
  shared_examples 'catalog' do

    storage_hash = Noop.hiera 'storage'
    node_name = Noop.hiera('node_name')
    network_metadata = Noop.hiera_hash 'network_metadata', {}
    roles = network_metadata['nodes'][node_name]['node_roles']
    vc_cinder_hash = Noop.hiera_structure('cinder/instances', [])
    vc_instance = vc_cinder_hash[0]
    vcenter_availability_zone_name = vc_instance['availability_zone_name']
    vcenter_host = vc_instance['vc_host']
    vcenter_password = vc_instance['vc_password']
    vcenter_user = vc_instance['vc_user']

    if storage_hash['debug']
      debug = storage_hash['debug']
    else
      debug = Noop.hiera 'debug', true
    end

    if storage_hash['volumes_ceph']
      if Noop.puppet_function 'member', roles, 'primary-controller' or Noop.puppet_function 'member', roles, 'controller'
        it 'should declare cinder vmware' do
          should contain_class('openstack_tasks::openstack_cinder::openstack_cinder')
        end
      end
    end

    it 'should configure /etc/cinder/cinder.d/vmware-vcenter.conf' do
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*enabled_backends=VMwareVcVmdk-backend\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*storage_availability_zone=#{vcenter_availability_zone_name}-cinder\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*default_availability_zone=#{vcenter_availability_zone_name}-cinder\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*debug=#{debug}\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*backend_host=#{vcenter_availability_zone_name}\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*volume_backend_name=VMwareVcVmdk-backend\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*volume_driver=cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*vmware_api_retry_count=10\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*vmware_host_ip=#{vcenter_host}\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*vmware_host_password=#{vcenter_password}\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*vmware_host_username=#{vcenter_user}\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*vmware_image_transfer_timeout_secs=7200\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*vmware_insecure = True\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*vmware_max_objects_retrieval=100\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*vmware_task_poll_interval=5\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*vmware_tmp_dir=/tmp\n}
      )
      should contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with_content(
        %r{\n\s*vmware_volume_folder=cinder-volumes\n}
      )
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end
