require 'spec_helper'

describe 'cinder::volume::iscsi' do

  let :req_params do
    {:iscsi_ip_address => '127.0.0.2'}
  end

  let :facts do
    {:osfamily => 'Debian'}
  end

  describe 'with default params' do

    let :params do
      req_params
    end

    it { should contain_cinder_config('DEFAULT/volume_driver').with(
           :value => 'cinder.volume.drivers.lvm.LVMISCSIDriver')}
    it { should contain_cinder_config('DEFAULT/iscsi_ip_address').with(:value => '127.0.0.2')}
    it { should contain_cinder_config('DEFAULT/iscsi_helper').with(:value => 'tgtadm')}
    it { should contain_cinder_config('DEFAULT/volume_group').with(:value => 'cinder-volumes')}

  end

  describe 'with iSER driver' do
    let(:params) { req_params.merge(
           :volume_driver => 'cinder.volume.drivers.lvm.LVMISERDriver')}

    it { should contain_cinder_config('DEFAULT/volume_driver').with(
           :value => 'cinder.volume.drivers.lvm.LVMISERDriver')}
  end

  describe 'with a unsupported iscsi helper' do
    let(:params) { req_params.merge(:iscsi_helper => 'fooboozoo')}

    it 'should raise an error' do
      expect {
        should compile
      }.to raise_error Puppet::Error, /Unsupported iscsi helper: fooboozoo/
    end
  end

  describe 'with RedHat' do

    let :params do
      req_params
    end

    let :facts do
      {:osfamily => 'RedHat'}
    end

    it { should contain_file_line('cinder include').with(
      :line => 'include /etc/cinder/volumes/*',
      :path => '/etc/tgt/targets.conf'
    ) }

  end

  describe 'with lioadm' do

    let :params do {
      :iscsi_ip_address => '127.0.0.2',
      :iscsi_helper => 'lioadm'
    }
    end

    let :facts do
      {:osfamily => 'RedHat'}
    end

    it { should contain_package('targetcli').with_ensure('present')}
    it { should contain_service('target').with(
      :ensure  => 'running',
      :enable  => 'true',
      :require => 'Package[targetcli]'
    ) }

  end

end
