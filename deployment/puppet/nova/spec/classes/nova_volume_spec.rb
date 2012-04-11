require 'spec_helper'

describe 'nova::volume' do

  let :pre_condition do
    'include nova'
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    it { should contain_service('nova-volume').with(
      'name'    => 'nova-volume',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should contain_package('nova-volume').with(
      'name'   => 'nova-volume',
      'ensure' => 'present',
      'notify' => 'Service[nova-volume]'
    )}
    it { should contain_service('tgtd').with(
      'name'   => 'tgt',
      'provider' => 'upstart',
      # FIXME(fc): rspec complains this value is 'nil' in the catalog
      #'ensure' => 'stopped',
      'enable' => false
    )}
    it { should contain_package('tgt').with_name('tgt') }
    describe 'with enabled as true' do
      let :params do
        {:enabled => true}
      end
      it { should contain_service('nova-volume').with(
        'name'     => 'nova-volume',
        'ensure'   => 'running',
        'enable'   => true
      )}
      it { should contain_service('tgtd').with(
        'name'     => 'tgt',
        'provider' => 'upstart',
        # FIXME(fc): rspec complains this value is 'nil' in the catalog
        #'ensure'   => 'running',
        'enable'   => 'true'
      )}
      describe 'and more specifically on debian os' do
        let :facts do
          { :osfamily => 'Debian', :operatingsystem => 'Debian' }
        end
        it { should contain_service('tgtd').with(
          'provider' => nil
        )}
      end
    end
  end
  describe 'on rhel' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it { should contain_service('nova-volume').with(
      'name'     => 'openstack-nova-volume',
      'ensure'   => 'stopped',
      'enable'   => false
    )}
    it { should contain_service('tgtd').with(
      'name'   => 'tgtd',
      # FIXME(fc): rspec complains this value is 'nil' in the catalog
      #'ensure'   => 'stopped',
      'enable' => false
    )}
    it { should_not contain_package('nova-volume') }
    it { should contain_package('tgt').with_name('scsi-target-utils')}
    describe 'with enabled' do
      let :params do
        {:enabled => true}
      end
      it { should contain_service('tgtd').with(
        'name'     => 'tgtd',
        'provider' => 'init',
        # FIXME(fc): rspec complains this value is 'nil' in the catalog
        #'ensure'   => 'running',
        'enable'   => 'true'
      )}
    end
  end
end
