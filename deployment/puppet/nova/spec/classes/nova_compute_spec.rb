require 'spec_helper'

describe 'nova::compute' do

  let :pre_condition do
    'include nova'
  end

  shared_examples 'nova-compute' do

    context 'with default parameters' do

      it 'installs nova-compute package and service' do
        is_expected.to contain_service('nova-compute').with({
          :name      => platform_params[:nova_compute_service],
          :ensure    => 'stopped',
          :hasstatus => true,
          :enable    => false
        })
        is_expected.to contain_package('nova-compute').with({
          :name => platform_params[:nova_compute_package],
          :tag  => ['openstack']
        })
      end

      it { is_expected.to contain_nova_config('DEFAULT/network_device_mtu').with(:ensure => 'absent') }
      it { is_expected.to_not contain_nova_config('DEFAULT/novncproxy_base_url') }

      it { is_expected.to_not contain_package('bridge-utils').with(
        :ensure => 'present',
        :before => 'Nova::Generic_service[compute]'
      ) }

      it { is_expected.to contain_package('pm-utils').with(
        :ensure => 'present'
      ) }

      it { is_expected.to contain_nova_config('DEFAULT/force_raw_images').with(:value => true) }

      it 'configures availability zones' do
        is_expected.to contain_nova_config('DEFAULT/default_availability_zone').with_value('nova')
        is_expected.to contain_nova_config('DEFAULT/internal_service_availability_zone').with_value('internal')
      end

      it { is_expected.to contain_nova_config('DEFAULT/heal_instance_info_cache_interval').with_value('60') }
    end

    context 'with overridden parameters' do
      let :params do
        { :enabled                            => true,
          :ensure_package                     => '2012.1-2',
          :vncproxy_host                      => '127.0.0.1',
          :network_device_mtu                 => 9999,
          :force_raw_images                   => false,
          :reserved_host_memory               => '0',
          :compute_manager                    => 'ironic.nova.compute.manager.ClusteredComputeManager',
          :default_availability_zone          => 'az1',
          :default_schedule_zone              => 'az2',
          :internal_service_availability_zone => 'az_int1',
          :heal_instance_info_cache_interval  => '120',
          :pci_passthrough                    => "[{\"vendor_id\":\"8086\",\"product_id\":\"0126\"},{\"vendor_id\":\"9096\",\"product_id\":\"1520\",\"physical_network\":\"physnet1\"}]"
        }
      end

      it 'installs nova-compute package and service' do
        is_expected.to contain_service('nova-compute').with({
          :name      => platform_params[:nova_compute_service],
          :ensure    => 'running',
          :hasstatus => true,
          :enable    => true
        })
        is_expected.to contain_package('nova-compute').with({
          :name   => platform_params[:nova_compute_package],
          :ensure => '2012.1-2',
          :tag    => ['openstack']
        })
      end

      it 'configures ironic in nova.conf' do
        is_expected.to contain_nova_config('DEFAULT/reserved_host_memory_mb').with_value('0')
        is_expected.to contain_nova_config('DEFAULT/compute_manager').with_value('ironic.nova.compute.manager.ClusteredComputeManager')
      end

      it 'configures network_device_mtu' do
        is_expected.to contain_nova_config('DEFAULT/network_device_mtu').with_value('9999')
      end

      it 'configures vnc in nova.conf' do
        is_expected.to contain_nova_config('DEFAULT/vnc_enabled').with_value(true)
        is_expected.to contain_nova_config('DEFAULT/vncserver_proxyclient_address').with_value('127.0.0.1')
        is_expected.to contain_nova_config('DEFAULT/novncproxy_base_url').with_value(
          'http://127.0.0.1:6080/vnc_auto.html'
        )
      end

      it 'configures availability zones' do
        is_expected.to contain_nova_config('DEFAULT/default_availability_zone').with_value('az1')
        is_expected.to contain_nova_config('DEFAULT/default_schedule_zone').with_value('az2')
        is_expected.to contain_nova_config('DEFAULT/internal_service_availability_zone').with_value('az_int1')
      end

      it { is_expected.to contain_nova_config('DEFAULT/heal_instance_info_cache_interval').with_value('120') }

      it { is_expected.to contain_nova_config('DEFAULT/force_raw_images').with(:value => false) }

      it 'configures nova pci_passthrough_whitelist entries' do
        is_expected.to contain_nova_config('DEFAULT/pci_passthrough_whitelist').with(
          'value' => "[{\"vendor_id\":\"8086\",\"product_id\":\"0126\"},{\"vendor_id\":\"9096\",\"product_id\":\"1520\",\"physical_network\":\"physnet1\"}]"
        )
      end
    end

    context 'with neutron_enabled set to false' do
      let :params do
        { :neutron_enabled => false }
      end

      it 'installs bridge-utils package for nova-network' do
        is_expected.to contain_package('bridge-utils').with(
          :ensure => 'present',
          :before => 'Nova::Generic_service[compute]'
        )
      end
    end

    context 'with vnc_enabled set to false' do
      let :params do
        { :vnc_enabled => false }
      end

      it 'disables vnc in nova.conf' do
        is_expected.to contain_nova_config('DEFAULT/vnc_enabled').with_value(false)
        is_expected.to contain_nova_config('DEFAULT/vncserver_proxyclient_address').with_value('127.0.0.1')
        is_expected.to_not contain_nova_config('DEFAULT/novncproxy_base_url')
      end
    end

    context 'with force_config_drive parameter set to true' do
      let :params do
        { :force_config_drive => true }
      end

      it { is_expected.to contain_nova_config('DEFAULT/force_config_drive').with_value(true) }
    end

    context 'while not managing service state' do
      let :params do
        { :enabled           => false,
          :manage_service    => false,
        }
      end

      it { is_expected.to contain_service('nova-compute').without_ensure }
    end

    context 'with instance_usage_audit parameter set to false' do
      let :params do
        { :instance_usage_audit => false, }
      end

      it { is_expected.to contain_nova_config('DEFAULT/instance_usage_audit').with_ensure('absent') }
      it { is_expected.to contain_nova_config('DEFAULT/instance_usage_audit_period').with_ensure('absent') }
    end

    context 'with instance_usage_audit parameter and wrong period' do
      let :params do
        { :instance_usage_audit        => true,
          :instance_usage_audit_period => 'fake', }
      end

      it { is_expected.to contain_nova_config('DEFAULT/instance_usage_audit').with_ensure('absent') }
      it { is_expected.to contain_nova_config('DEFAULT/instance_usage_audit_period').with_ensure('absent') }
    end

    context 'with instance_usage_audit parameter and period' do
      let :params do
        { :instance_usage_audit        => true,
          :instance_usage_audit_period => 'year', }
      end

      it { is_expected.to contain_nova_config('DEFAULT/instance_usage_audit').with_value(true) }
      it { is_expected.to contain_nova_config('DEFAULT/instance_usage_audit_period').with_value('year') }
    end
    context 'with vnc_keymap set to fr' do
      let :params do
        { :vnc_keymap => 'fr', }
      end

      it { is_expected.to contain_nova_config('DEFAULT/vnc_keymap').with_value('fr') }
    end
  end


  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :nova_compute_package => 'nova-compute',
        :nova_compute_service => 'nova-compute' }
    end

    it_behaves_like 'nova-compute'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :nova_compute_package => 'openstack-nova-compute',
        :nova_compute_service => 'openstack-nova-compute' }
    end

    it_behaves_like 'nova-compute'
  end
end
