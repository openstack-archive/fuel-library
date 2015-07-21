require 'spec_helper'
describe 'nova::compute::libvirt' do

  let :pre_condition do
    "include nova\ninclude nova::compute"
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    describe 'with default parameters' do

      it { is_expected.to contain_class('nova::params')}

      it { is_expected.to contain_package('nova-compute-kvm').with(
        :ensure => 'present',
        :before => 'Package[nova-compute]',
        :tag    => ['openstack']
      ) }

      it { is_expected.to contain_package('libvirt').with(
        :name   => 'libvirt-bin',
        :ensure => 'present'
      ) }

      it { is_expected.to contain_service('libvirt').with(
        :name     => 'libvirt-bin',
        :enable   => true,
        :ensure   => 'running',
        :provider => 'upstart',
        :require  => 'Package[libvirt]',
        :before   => ['Service[nova-compute]']
      )}

      it { is_expected.to contain_nova_config('DEFAULT/compute_driver').with_value('libvirt.LibvirtDriver')}
      it { is_expected.to contain_nova_config('libvirt/virt_type').with_value('kvm')}
      it { is_expected.to contain_nova_config('libvirt/cpu_mode').with_value('host-model')}
      it { is_expected.to contain_nova_config('libvirt/disk_cachemodes').with_ensure('absent')}
      it { is_expected.to contain_nova_config('libvirt/inject_password').with_value(false)}
      it { is_expected.to contain_nova_config('libvirt/inject_key').with_value(false)}
      it { is_expected.to contain_nova_config('libvirt/inject_partition').with_value(-2)}
      it { is_expected.to contain_nova_config('DEFAULT/vncserver_listen').with_value('127.0.0.1')}
      it { is_expected.to contain_nova_config('DEFAULT/remove_unused_base_images').with_ensure('absent')}
      it { is_expected.to contain_nova_config('DEFAULT/remove_unused_original_minimum_age_seconds').with_ensure('absent')}
      it { is_expected.to contain_nova_config('libvirt/remove_unused_kernels').with_ensure('absent')}
      it { is_expected.to contain_nova_config('libvirt/remove_unused_resized_minimum_age_seconds').with_ensure('absent')}
    end

    describe 'with params' do
      let :params do
        { :libvirt_virt_type                          => 'qemu',
          :vncserver_listen                           => '0.0.0.0',
          :libvirt_cpu_mode                           => 'host-passthrough',
          :libvirt_disk_cachemodes                    => ['file=directsync','block=none'],
          :remove_unused_base_images                  => true,
          :remove_unused_kernels                      => true,
          :remove_unused_resized_minimum_age_seconds  => 3600,
          :remove_unused_original_minimum_age_seconds => 3600,
          :libvirt_service_name                       => 'custom_service',
          :compute_driver                             => 'libvirt.FoobarDriver',
        }
      end

      it { is_expected.to contain_nova_config('DEFAULT/compute_driver').with_value('libvirt.FoobarDriver')}
      it { is_expected.to contain_nova_config('libvirt/virt_type').with_value('qemu')}
      it { is_expected.to contain_nova_config('libvirt/cpu_mode').with_value('host-passthrough')}
      it { is_expected.to contain_nova_config('libvirt/disk_cachemodes').with_value('file=directsync,block=none')}
      it { is_expected.to contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
      it { is_expected.to contain_nova_config('DEFAULT/remove_unused_base_images').with_value(true)}
      it { is_expected.to contain_nova_config('DEFAULT/remove_unused_original_minimum_age_seconds').with_value(3600)}
      it { is_expected.to contain_nova_config('libvirt/remove_unused_kernels').with_value(true)}
      it { is_expected.to contain_nova_config('libvirt/remove_unused_resized_minimum_age_seconds').with_value(3600)}
      it { is_expected.to contain_service('libvirt').with(
        :name     => 'custom_service',
        :enable   => true,
        :ensure   => 'running',
        :require  => 'Package[libvirt]',
        :before   => ['Service[nova-compute]']
      )}
    end

    describe 'with migration_support enabled' do

      context 'with vncserver_listen set to 0.0.0.0' do
        let :params do
          { :vncserver_listen  => '0.0.0.0',
            :migration_support => true }
        end

        it { is_expected.to contain_class('nova::migration::libvirt')}
        it { is_expected.to contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
        it { is_expected.to contain_file_line('/etc/default/libvirt-bin libvirtd opts').with(:line => 'libvirtd_opts="-d -l"') }
      end

      context 'with vncserver_listen set to ::0' do
        let :params do
          { :vncserver_listen  => '::0',
            :migration_support => true }
        end

        it { is_expected.to contain_class('nova::migration::libvirt')}
        it { is_expected.to contain_nova_config('DEFAULT/vncserver_listen').with_value('::0')}
        it { is_expected.to contain_file_line('/etc/default/libvirt-bin libvirtd opts').with(:line => 'libvirtd_opts="-d -l"') }
      end

      context 'with vncserver_listen not set to 0.0.0.0' do
        let :params do
          { :vncserver_listen  => '127.0.0.1',
            :migration_support => true }
        end

        it { expect { is_expected.to contain_class('nova::compute::libvirt') }.to \
          raise_error(Puppet::Error, /For migration support to work, you MUST set vncserver_listen to '0.0.0.0' or '::0'/) }
      end

      context 'with custom libvirt service name on Debian platforms' do
        let :params do
          { :libvirt_service_name  => 'libvirtd',
            :vncserver_listen      => '0.0.0.0',
            :migration_support     => true }
        end
        it { is_expected.to contain_file_line('/etc/default/libvirtd libvirtd opts').with(:line => 'libvirtd_opts="-d -l"') }

      end
    end
  end


  describe 'on rhel platforms' do
    let :facts do
      { :operatingsystem => 'RedHat', :osfamily => 'RedHat',
        :operatingsystemrelease => 6.5,
        :operatingsystemmajrelease => '6' }
    end

    describe 'with default parameters' do

      it { is_expected.to contain_class('nova::params')}

      it { is_expected.to contain_package('libvirt').with(
        :name   => 'libvirt-daemon-kvm',
        :ensure => 'present',
      ) }

      it { is_expected.to contain_package('libvirt-nwfilter').with(
        :name   => 'libvirt-daemon-config-nwfilter',
        :ensure => 'present',
        :before  => 'Service[libvirt]',
      ) }

      it { is_expected.to contain_service('libvirt').with(
        :name     => 'libvirtd',
        :enable   => true,
        :ensure   => 'running',
        :provider => 'init',
        :require  => 'Package[libvirt]',
        :before   => ['Service[nova-compute]']
      )}
      it { is_expected.to contain_service('messagebus').with(
        :ensure   => 'running',
        :enable   => true,
        :before   => ['Service[libvirt]'],
        :provider => 'init',
        :name     => 'messagebus'
      ) }

      describe 'on rhel 7' do
        let :facts do
          super().merge(:operatingsystemrelease => 7.0)
          super().merge(:operatingsystemmajrelease => '7')
        end

        it { is_expected.to contain_service('libvirt').with(
          :provider => nil
        )}

        it { is_expected.to contain_service('messagebus').with(
          :provider => nil,
          :name     => 'dbus'
        )}
      end

      it { is_expected.to contain_nova_config('DEFAULT/compute_driver').with_value('libvirt.LibvirtDriver')}
      it { is_expected.to contain_nova_config('libvirt/virt_type').with_value('kvm')}
      it { is_expected.to contain_nova_config('libvirt/inject_password').with_value(false)}
      it { is_expected.to contain_nova_config('libvirt/inject_key').with_value(false)}
      it { is_expected.to contain_nova_config('libvirt/inject_partition').with_value(-2)}
      it { is_expected.to contain_nova_config('DEFAULT/vncserver_listen').with_value('127.0.0.1')}
      it { is_expected.to contain_nova_config('DEFAULT/remove_unused_base_images').with_ensure('absent')}
      it { is_expected.to contain_nova_config('DEFAULT/remove_unused_original_minimum_age_seconds').with_ensure('absent')}
      it { is_expected.to contain_nova_config('libvirt/remove_unused_kernels').with_ensure('absent')}
      it { is_expected.to contain_nova_config('libvirt/remove_unused_resized_minimum_age_seconds').with_ensure('absent')}
    end

    describe 'with params' do
      let :params do
        { :libvirt_virt_type                          => 'qemu',
          :vncserver_listen                           => '0.0.0.0',
          :remove_unused_base_images                  => true,
          :remove_unused_kernels                      => true,
          :remove_unused_resized_minimum_age_seconds  => 3600,
          :remove_unused_original_minimum_age_seconds => 3600
        }
      end

      it { is_expected.to contain_nova_config('libvirt/virt_type').with_value('qemu')}
      it { is_expected.to contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
      it { is_expected.to contain_nova_config('DEFAULT/remove_unused_base_images').with_value(true)}
      it { is_expected.to contain_nova_config('DEFAULT/remove_unused_original_minimum_age_seconds').with_value(3600)}
      it { is_expected.to contain_nova_config('libvirt/remove_unused_kernels').with_value(true)}
      it { is_expected.to contain_nova_config('libvirt/remove_unused_resized_minimum_age_seconds').with_value(3600)}
      it { is_expected.to contain_package('libvirt').with(
        :name   => 'libvirt-daemon-kvm',
        :ensure => 'present'
      ) }
    end

    describe 'with migration_support enabled' do

      context 'with vncserver_listen set to 0.0.0.0' do
        let :params do
          { :vncserver_listen  => '0.0.0.0',
            :migration_support => true }
        end

        it { is_expected.to contain_class('nova::migration::libvirt')}
        it { is_expected.to contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
      end

      context 'with vncserver_listen not set to 0.0.0.0' do
        let :params do
          { :vncserver_listen  => '127.0.0.1',
            :migration_support => true }
        end

        it { expect { is_expected.to contain_class('nova::compute::libvirt') }.to \
          raise_error(Puppet::Error, /For migration support to work, you MUST set vncserver_listen to '0.0.0.0'/) }
      end
    end

    describe 'with default parameters on Fedora' do
      let :facts do
        { :operatingsystem => 'Fedora', :osfamily => 'RedHat' }
      end

      it { is_expected.to contain_class('nova::params')}

      it { is_expected.to contain_package('libvirt').with(
        :name   => 'libvirt-daemon-kvm',
        :ensure => 'present'
      ) }

      it { is_expected.to contain_package('libvirt-nwfilter').with(
        :name   => 'libvirt-daemon-config-nwfilter',
        :ensure => 'present',
        :before  => 'Service[libvirt]',
      ) }

      it { is_expected.to contain_service('libvirt').with(
        :name     => 'libvirtd',
        :enable   => true,
        :ensure   => 'running',
        :provider => nil,
        :require  => 'Package[libvirt]',
        :before   => ['Service[nova-compute]']
      )}

      it { is_expected.to contain_nova_config('DEFAULT/compute_driver').with_value('libvirt.LibvirtDriver')}
      it { is_expected.to contain_nova_config('libvirt/virt_type').with_value('kvm')}
      it { is_expected.to contain_nova_config('DEFAULT/vncserver_listen').with_value('127.0.0.1')}
    end

  end
end
