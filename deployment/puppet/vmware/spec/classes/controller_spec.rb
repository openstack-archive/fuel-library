require 'spec_helper'

describe 'vmware::controller' do
  let(:facts) { { :osfamily => 'debian' }	}

  it 'must disable nova-compute' do
    should contain_nova__generic_service('compute').with({
      'enabled' => 'false'
    })
  end

  context 'in HA deployment mode' do
    let(:params) { { :ha_mode => true } }

    it 'should install nova-compute OCF script' do
      should contain_file('vcenter-nova-compute-ocf').with({
        'path'   => '/usr/lib/ocf/resource.d/mirantis/nova-compute',
        'source' => 'puppet:///modules/vmware/ocf/nova-compute',
      })
    end
  end

  it 'must properly configure novncproxy_base_url' do
    should contain_nova_config('DEFAULT/novncproxy_base_url').with({
      'value' => "http://0.0.0.0:6080/vnc_auto.html",
    })
  end

  it 'must install cirros-testvmware package' do
    should contain_package('cirros-testvmware')
  end

  it 'must install python-suds package' do
    should contain_package('python-suds')
  end

end
