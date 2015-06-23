require 'spec_helper'

describe 'cinder::ceilometer' do

  describe 'with default parameters' do
    it 'contains default values' do
      is_expected.to contain_cinder_config('DEFAULT/notification_driver').with(
        :value => 'cinder.openstack.common.notifier.rpc_notifier')
    end
  end
end
