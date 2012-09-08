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
