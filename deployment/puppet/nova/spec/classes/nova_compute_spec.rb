require 'spec_helper'

describe 'nova::compute' do

  let :pre_condition do
    'include nova'
  end

  describe 'with required params provided' do

    let :params do
      {
        :vncproxy_host   => '127.0.0.1',
        :neutron_enabled => true
      }
    end

    describe 'on debian platforms' do
      let :facts do
        { :osfamily => 'Debian' }
      end

      it { should contain_nova_config('DEFAULT/vnc_enabled').with_value(true) }
      it { should contain_nova_config('DEFAULT/vncserver_proxyclient_address').with_value('127.0.0.1') }
      it { should contain_nova_config('DEFAULT/novncproxy_base_url').with_value(
        'http://127.0.0.1:6080/vnc_auto.html'
      ) }

      it { should contain_service('nova-compute').with(
        'name'      => 'nova-compute',
        'ensure'    => 'stopped',
        'hasstatus' => true,
        'enable'    => false
      )}
      it { should contain_package('nova-compute').with(
        'name'   => 'nova-compute',
        'ensure' => 'present',
        'notify' => 'Service[nova-compute]'
      ) }
      it { should_not contain_package('bridge-utils').with(
        :ensure => 'present',
        :before => 'Nova::Generic_service[compute]'
      ) }
      it { should contain_package('pm-utils').with(
        :ensure => 'present'
      ) }

      describe 'with vnc_enabled set to true' do
        let :params do
          {
            :enabled       => true,
            :vncproxy_host => '127.0.0.1'
          }
        end
      it { should contain_service('nova-compute').with(
        'name'      => 'nova-compute',
        'ensure'    => 'running',
        'hasstatus' => true,
        'enable'    => true
      )}
      end
      describe 'with vnc_enabled set to false' do

        let :params do
          {:vnc_enabled => false}
        end

        it { should contain_nova_config('DEFAULT/vnc_enabled').with_value(false) }
        it { should contain_nova_config('DEFAULT/vncserver_proxyclient_address').with_value('127.0.0.1')}
        it { should_not contain_nova_config('DEFAULT/novncproxy_base_url') }

      end
      describe 'with force_config_drive set to true' do

        let :params do
          {:force_config_drive => true}
        end

        it { should contain_nova_config('DEFAULT/force_config_drive').with_value('true') }

      end
      describe 'with package version' do
        let :params do
          {:ensure_package => '2012.1-2'}
        end
        it { should contain_package('nova-compute').with(
          'ensure' => '2012.1-2'
        )}
      end
    end
    describe 'on rhel' do
      let :facts do
        { :osfamily => 'RedHat' }
      end
      it { should contain_service('nova-compute').with(
        'name'      => 'openstack-nova-compute',
        'ensure'    => 'stopped',
        'hasstatus' => true,
        'enable'    => false
      )}
      it { should contain_package('nova-compute').with_name('openstack-nova-compute') }
    end
  end
end
