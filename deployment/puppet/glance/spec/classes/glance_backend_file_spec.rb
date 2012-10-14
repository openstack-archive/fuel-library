require 'spec_helper'

describe 'glance::backend::file' do
  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :pre_condition do
    'class { "glance::api": keystone_password => "pass" }'
  end

  it { should contain_glance_api_config('DEFAULT/default_store').with_value('file') }
  it { should contain_glance_api_config('DEFAULT/filesystem_store_datadir').with_value('/var/lib/glance/images/') }

  describe 'when overriding datadir' do
    let :params do
      {:filesystem_store_datadir => '/tmp/'}
    end
    it { should contain_glance_api_config('DEFAULT/filesystem_store_datadir').with_value('/tmp/') }
  end
end
