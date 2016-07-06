require 'spec_helper'
require 'shared-examples'
manifest = 'roles/ironic-compute.pp'

describe manifest do
  shared_examples 'catalog' do
    ironic_user_password = Noop.hiera_structure 'ironic/user_password'
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    let (:memcached_servers) { Noop.hiera 'memcached_servers' }

    if ironic_enabled
      it 'nova config should have correct ironic settings' do
        should contain_nova_config('ironic/admin_password').with(:value => ironic_user_password)
        should contain_nova_config('DEFAULT/compute_driver').with(:value => 'ironic.IronicDriver')
        should contain_nova_config('DEFAULT/compute_manager').with(:value => 'ironic.nova.compute.manager.ClusteredComputeManager')
      end

      it 'nova config should have reserved_host_memory_mb set to 0' do
        should contain_nova_config('DEFAULT/reserved_host_memory_mb').with(:value => '0')
      end

      it 'nova config should contain right memcached servers list' do
        should contain_nova_config('DEFAULT/memcached_servers').with(
          'value' => memcached_servers.join(','),
        )
      end

      it 'nova-compute.conf should have host set to "ironic-compute"' do
        should contain_file('/etc/nova/nova-compute.conf').with('content'  => "[DEFAULT]\nhost=ironic-compute")
      end

      it 'nova-compute should manages by pacemaker, and should be disabled as system service' do
        expect(subject).to contain_cs_resource('p_nova_compute_ironic').with(
                             :name            => "p_nova_compute_ironic",
                             :ensure          => "present",
                             :primitive_class => "ocf",
                             :provided_by     => "pacemaker",
                             :primitive_type  => "nova-compute",
                             :metadata        => {"resource-stickiness" => "1"},
                             :parameters      => {"config"                => "/etc/nova/nova.conf",
                                                  "pid"                   => "/var/run/nova/nova-compute-ironic.pid",
                                                  "additional_parameters" => "--config-file=/etc/nova/nova-compute.conf"
                                                 },
                             )
        expect(subject).to contain_service('p_nova_compute_ironic').with(
                             :name     => "p_nova_compute_ironic",
                             :ensure   => "running",
                             :enable   => true,
                             :provider => "pacemaker",
                             )
        expect(subject).to contain_service('nova-compute').with(
                             :name     => "nova-compute",
                             :ensure   => "stopped",
                             :enable   => false,
                             )
      end
    end
  end

  test_ubuntu_and_centos manifest
end
