require 'spec_helper'

describe 'vmware::ceilometer' do
  let(:facts) { { :osfamily => 'debian' } }

  # We are using ceilometer::agent::compute which inherits
  # ceilometer class. In ceilometer ceilometer::agent::compute class
  # parameter metering_secret isn't set, so default value 'false' will be used.
  # It's boolean value, not string, so test validate_string($metering_secret)
  # will fail in ceilometer class.
  it 'must disable ceilometer-agent-compute' do
    should contain_class('ceilometer::agent::compute').with({
      'enabled' => 'false'
    })
  end

  context 'in HA deployment mode' do
    let(:params) { { :ha_mode => true } }

    it 'should install ceilometer-agent-compute OCF script' do
      should contain_file('ceilometer-agent-compute-ocf').with({
        'path'   => '/usr/lib/ocf/resource.d/mirantis/ceilometer-agent-compute',
        'source' => 'puppet:///modules/vmware/ocf/ceilometer-agent-compute',
      })
    end
  end
end
