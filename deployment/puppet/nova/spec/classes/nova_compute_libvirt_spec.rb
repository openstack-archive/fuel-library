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

      it { should contain_class('nova::params')}

      it { should contain_package('nova-compute-kvm').with(
        :ensure => 'present',
        :before => 'Package[nova-compute]'
      ) }

      it { should contain_package('libvirt').with(
        :name   => 'libvirt-bin',
        :ensure => 'present'
      ) }

      it { should contain_service('libvirt').with(
        :name     => 'libvirt-bin',
        :enable   => true,
        :ensure   => 'running',
        :provider => 'upstart',
        :require  => 'Package[libvirt]',
        :before   => 'Service[nova-compute]'
      )}

      it { should contain_nova_config('DEFAULT/compute_driver').with_value('libvirt.LibvirtDriver')}
      it { should contain_nova_config('libvirt/virt_type').with_value('kvm')}
      it { should contain_nova_config('libvirt/cpu_mode').with_value('host-model')}
      it { should contain_nova_config('libvirt/disk_cachemodes').with_ensure('absent')}
      it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('127.0.0.1')}
      it { should contain_nova_config('DEFAULT/remove_unused_base_images').with_ensure('absent')}
      it { should contain_nova_config('DEFAULT/remove_unused_original_minimum_age_seconds').with_ensure('absent')}
      it { should contain_nova_config('libvirt/remove_unused_kernels').with_ensure('absent')}
      it { should contain_nova_config('libvirt/remove_unused_resized_minimum_age_seconds').with_ensure('absent')}
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
          :remove_unused_original_minimum_age_seconds => 3600
        }
      end

      it { should contain_nova_config('libvirt/virt_type').with_value('qemu')}
      it { should contain_nova_config('libvirt/cpu_mode').with_value('host-passthrough')}
      it { should contain_nova_config('libvirt/disk_cachemodes').with_value('file=directsync,block=none')}
      it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
      it { should contain_nova_config('DEFAULT/remove_unused_base_images').with_value(true)}
      it { should contain_nova_config('DEFAULT/remove_unused_original_minimum_age_seconds').with_value(3600)}
      it { should contain_nova_config('libvirt/remove_unused_kernels').with_value(true)}
      it { should contain_nova_config('libvirt/remove_unused_resized_minimum_age_seconds').with_value(3600)}
    end

    describe 'with deprecated params' do
      let :params do
        { :libvirt_type => 'qemu'
        }
      end

      it { should contain_nova_config('libvirt/virt_type').with_value('qemu')}
    end

    describe 'with migration_support enabled' do

      context 'with vncserver_listen set to 0.0.0.0' do
        let :params do
          { :vncserver_listen  => '0.0.0.0',
            :migration_support => true }
        end

        it { should contain_class('nova::migration::libvirt')}
        it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
      end

      context 'with vncserver_listen not set to 0.0.0.0' do
        let :params do
          { :vncserver_listen  => '127.0.0.1',
            :migration_support => true }
        end

        it { expect { should contain_class('nova::compute::libvirt') }.to \
          raise_error(Puppet::Error, /For migration support to work, you MUST set vncserver_listen to '0.0.0.0'/) }
      end
    end
  end


  describe 'on rhel platforms' do
    let :facts do
      { :operatingsystem => 'RedHat', :osfamily => 'RedHat',
        :operatingsystemrelease => 6.5 }
    end

    describe 'with default parameters' do

      it { should contain_class('nova::params')}

      it { should contain_package('libvirt').with(
        :name   => 'libvirt',
        :ensure => 'present'
      ) }

      it { should contain_service('libvirt').with(
        :name     => 'libvirtd',
        :enable   => true,
        :ensure   => 'running',
        :provider => nil,
        :require  => 'Package[libvirt]',
        :before   => 'Service[nova-compute]'
      )}
      it { should contain_service('messagebus').with(
        :ensure   => 'running',
        :enable   => true,
        :before   => 'Service[libvirt]',
        :provider => nil
      ) }

      describe 'on rhel 7' do
        let :facts do
          super().merge(:operatingsystemrelease => 7.0)
        end

        it { should contain_service('libvirt').with(
          :provider => nil
        )}

        it { should contain_service('messagebus').with(
          :provider => nil
        )}
      end

      it { should contain_nova_config('DEFAULT/compute_driver').with_value('libvirt.LibvirtDriver')}
      it { should contain_nova_config('libvirt/virt_type').with_value('kvm')}
      it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('127.0.0.1')}
      it { should contain_nova_config('DEFAULT/remove_unused_base_images').with_ensure('absent')}
      it { should contain_nova_config('DEFAULT/remove_unused_original_minimum_age_seconds').with_ensure('absent')}
      it { should contain_nova_config('libvirt/remove_unused_kernels').with_ensure('absent')}
      it { should contain_nova_config('libvirt/remove_unused_resized_minimum_age_seconds').with_ensure('absent')}
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

      it { should contain_nova_config('libvirt/virt_type').with_value('qemu')}
      it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
      it { should contain_nova_config('DEFAULT/remove_unused_base_images').with_value(true)}
      it { should contain_nova_config('DEFAULT/remove_unused_original_minimum_age_seconds').with_value(3600)}
      it { should contain_nova_config('libvirt/remove_unused_kernels').with_value(true)}
      it { should contain_nova_config('libvirt/remove_unused_resized_minimum_age_seconds').with_value(3600)}
    end

    describe 'with deprecated params' do
      let :params do
        { :libvirt_type => 'qemu'
        }
      end

      it { should contain_nova_config('libvirt/virt_type').with_value('qemu')}
    end

    describe 'with migration_support enabled' do

      context 'with vncserver_listen set to 0.0.0.0' do
        let :params do
          { :vncserver_listen  => '0.0.0.0',
            :migration_support => true }
        end

        it { should contain_class('nova::migration::libvirt')}
        it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
      end

      context 'with vncserver_listen not set to 0.0.0.0' do
        let :params do
          { :vncserver_listen  => '127.0.0.1',
            :migration_support => true }
        end

        it { expect { should contain_class('nova::compute::libvirt') }.to \
          raise_error(Puppet::Error, /For migration support to work, you MUST set vncserver_listen to '0.0.0.0'/) }
      end
    end

    describe 'with default parameters on Fedora' do
      let :facts do
        { :operatingsystem => 'Fedora', :osfamily => 'RedHat' }
      end

      it { should contain_class('nova::params')}

      it { should contain_package('libvirt').with(
        :name   => 'libvirt',
        :ensure => 'present'
      ) }

      it { should contain_service('libvirt').with(
        :name     => 'libvirtd',
        :enable   => true,
        :ensure   => 'running',
        :provider => nil,
        :require  => 'Package[libvirt]',
        :before   => 'Service[nova-compute]'
      )}

      it { should contain_nova_config('DEFAULT/compute_driver').with_value('libvirt.LibvirtDriver')}
      it { should contain_nova_config('libvirt/virt_type').with_value('kvm')}
      it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('127.0.0.1')}
    end

  end
end
