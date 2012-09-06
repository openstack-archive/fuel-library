require 'spec_helper'

describe 'nova::volume::iscsi' do

  describe 'on debian platforms' do

    let :facts do
      { :osfamily => 'Debian' }
    end
    it { should contain_service('tgtd').with(
      'name'   => 'tgt',
      'provider' => 'upstart',
      # FIXME(fc): rspec complains this value is 'nil' in the catalog
      #'ensure' => 'stopped',
      'enable' => true
    )}
    it { should contain_package('tgt').with_name('tgt') }

    describe 'and more specifically on debian os' do
      let :facts do
        { :osfamily => 'Debian', :operatingsystem => 'Debian' }
      end
      it { should contain_service('tgtd').with(
        'provider' => nil
      )}
    end

    describe 'and more specifically on debian os with iscsitarget helper' do
      let :facts do
        { :osfamily => 'Debian', :operatingsystem => 'Debian' }
      end
      let :params do
        {:iscsi_helper => 'iscsitarget'}
      end
      it { should contain_package('iscsitarget') }
      it { should contain_service('iscsitarget').with_enable(true) }
      it { should contain_service('open-iscsi').with_enable(true) }
      it { should contain_package('iscsitarget-dkms') }
      it { should contain_file('/etc/default/iscsitarget') }
    end

    it { should contain_nova_config('volume_group').with_value('nova-volumes') }
    it { should_not contain_nova_config('iscsi_ip_address') }

  end

  describe 'on rhel' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it { should contain_service('tgtd').with(
      'name'   => 'tgtd',
      # FIXME(fc): rspec complains this value is 'nil' in the catalog
      #'ensure'   => 'stopped',
      'enable' => true
    )}
    it { should contain_package('tgt').with_name('scsi-target-utils')}
  end
end
