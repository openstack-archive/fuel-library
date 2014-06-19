require 'spec_helper'

describe 'cinder::volume::iscsi' do

  let :req_params do {
    :iscsi_ip_address => '127.0.0.2',
    :iscsi_helper => 'tgtadm'
  }
  end

  let :facts do
    {:osfamily => 'Debian'}
  end

  describe 'with default params' do

    let :params do
      req_params
    end

    it { should contain_cinder_config('DEFAULT/iscsi_ip_address').with(
      :value => '127.0.0.2'
    ) }
    it { should contain_cinder_config('DEFAULT/iscsi_helper').with(
      :value => 'tgtadm'
    ) }
    it { should contain_cinder_config('DEFAULT/volume_group').with(
      :value => 'cinder-volumes'
    ) }

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

  end

end
