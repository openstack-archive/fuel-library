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

    it { is_expected.to contain_cinder_config('DEFAULT/volume_driver').with(
           :value => 'cinder.volume.drivers.lvm.LVMVolumeDriver')}
    it { is_expected.to contain_cinder_config('DEFAULT/iscsi_ip_address').with(:value => '127.0.0.2')}
    it { is_expected.to contain_cinder_config('DEFAULT/iscsi_helper').with(:value => 'tgtadm')}
    it { is_expected.to contain_cinder_config('DEFAULT/volume_group').with(:value => 'cinder-volumes')}
    it { is_expected.to contain_cinder_config('DEFAULT/volumes_dir').with(:value => '/var/lib/cinder/volumes')}
    it { is_expected.to contain_cinder_config('DEFAULT/iscsi_protocol').with(:value => 'iscsi')}

  end

  describe 'with a non-default $volumes_dir' do
    let(:params) { req_params.merge(:volumes_dir => '/etc/cinder/volumes')}

    it 'should contain a cinder::backend::iscsi resource with /etc/cinder/volumes as $volumes dir' do
      is_expected.to contain_cinder__backend__iscsi('DEFAULT').with({
        :volumes_dir => '/etc/cinder/volumes'
      })
    end

  end

  describe 'with a unsupported iscsi helper' do
    let(:params) { req_params.merge(:iscsi_helper => 'fooboozoo')}

    it_raises 'a Puppet::Error', /Unsupported iscsi helper: fooboozoo/
  end

  describe 'on RHEL Platforms' do

    let :params do
      req_params
    end

    let :facts do
      {:osfamily => 'RedHat',
       :operatingsystem => 'RedHat',
       :operatingsystemrelease => 6.5,
       :operatingsystemmajrelease => '6'}
    end

    it { is_expected.to contain_file_line('cinder include').with(
      :line => 'include /var/lib/cinder/volumes/*',
      :path => '/etc/tgt/targets.conf'
    ) }

  end

  describe 'with lioadm' do

    let :params do {
      :iscsi_ip_address => '127.0.0.2',
      :iscsi_helper     => 'lioadm'
    }
    end

    let :facts do
      {:osfamily => 'RedHat',
       :operatingsystem => 'RedHat',
       :operatingsystemrelease => 7.0,
       :operatingsystemmajrelease => '7'}
    end

    it { is_expected.to contain_package('targetcli').with_ensure('present')}
    it { is_expected.to contain_service('target').with(
      :ensure  => 'running',
      :enable  => 'true',
      :require => 'Package[targetcli]'
    ) }

  end

  describe 'iscsi volume driver with additional configuration' do
    let(:params) { req_params.merge({:extra_options => {'iscsi_backend/param1' => {'value' => 'value1'}}}) }

    it 'configure iscsi volume with additional configuration' do
      should contain_cinder__backend__iscsi('DEFAULT').with({
        :extra_options => {'iscsi_backend/param1' => {'value' => 'value1'}}
      })
    end
  end

end
