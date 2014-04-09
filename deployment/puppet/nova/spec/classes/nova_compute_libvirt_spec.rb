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

      it { should include_class('nova::params')}

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
        :ensure   => 'running',
        :provider => 'upstart',
        :require  => 'Package[libvirt]',
        :before   => 'Service[nova-compute]'
      )}

      it { should contain_nova_config('DEFAULT/compute_driver').with_value('libvirt.LibvirtDriver')}
      it { should contain_nova_config('DEFAULT/libvirt_type').with_value('kvm')}
      it { should contain_nova_config('DEFAULT/connection_type').with_value('libvirt')}
      it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('127.0.0.1')}
    end

    describe 'with params' do
      let :params do
        { :libvirt_type     => 'qemu',
          :vncserver_listen => '0.0.0.0'
        }
      end

      it { should contain_nova_config('DEFAULT/libvirt_type').with_value('qemu')}
      it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
    end

    describe 'with migration_support enabled' do

      context 'with vncserver_listen set to 0.0.0.0' do
        let :params do
          { :vncserver_listen => '0.0.0.0',
            :migration_support => true }
        end

        it { should include_class('nova::migration::libvirt')}
        it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
      end

      context 'with vncserver_listen not set to 0.0.0.0' do
        let :params do
          { :vncserver_listen => '127.0.0.1',
            :migration_support => true }
        end

        it { expect { should contain_class('nova::compute::libvirt') }.to \
          raise_error(Puppet::Error, /For migration support to work, you MUST set vncserver_listen to '0.0.0.0'/) }
      end
    end
  end


  describe 'on rhel platforms' do
    let :facts do
      { :operatingsystem => 'RedHat', :osfamily => 'RedHat' }
    end

    describe 'with default parameters' do

      it { should include_class('nova::params')}

      it { should contain_package('libvirt').with(
        :name   => 'libvirt',
        :ensure => 'present'
      ) }

      it { should contain_service('libvirt').with(
        :name     => 'libvirtd',
        :ensure   => 'running',
        :provider => 'init',
        :require  => 'Package[libvirt]',
        :before   => 'Service[nova-compute]'
      )}
      it { should contain_service('messagebus').with(
        :ensure   => 'running',
        :enable   => true,
        :before   => 'Service[libvirt]',
        :provider => 'init'
      ) }

      it { should contain_nova_config('DEFAULT/compute_driver').with_value('libvirt.LibvirtDriver')}
      it { should contain_nova_config('DEFAULT/libvirt_type').with_value('kvm')}
      it { should contain_nova_config('DEFAULT/connection_type').with_value('libvirt')}
      it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('127.0.0.1')}
    end

    describe 'with params' do
      let :params do
        { :libvirt_type     => 'qemu',
          :vncserver_listen => '0.0.0.0'
        }
      end

      it { should contain_nova_config('DEFAULT/libvirt_type').with_value('qemu')}
      it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
    end

    describe 'with migration_support enabled' do

      context 'with vncserver_listen set to 0.0.0.0' do
        let :params do
          { :vncserver_listen => '0.0.0.0',
            :migration_support => true }
        end

        it { should include_class('nova::migration::libvirt')}
        it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('0.0.0.0')}
      end

      context 'with vncserver_listen not set to 0.0.0.0' do
        let :params do
          { :vncserver_listen => '127.0.0.1',
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

      it { should include_class('nova::params')}

      it { should contain_package('libvirt').with(
        :name   => 'libvirt',
        :ensure => 'present'
      ) }

      it { should contain_service('libvirt').with(
        :name     => 'libvirtd',
        :ensure   => 'running',
        :provider => nil,
        :require  => 'Package[libvirt]',
        :before   => 'Service[nova-compute]'
      )}

      it { should contain_nova_config('DEFAULT/compute_driver').with_value('libvirt.LibvirtDriver')}
      it { should contain_nova_config('DEFAULT/libvirt_type').with_value('kvm')}
      it { should contain_nova_config('DEFAULT/connection_type').with_value('libvirt')}
      it { should contain_nova_config('DEFAULT/vncserver_listen').with_value('127.0.0.1')}
    end

  end
end
