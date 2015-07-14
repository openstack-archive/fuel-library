require 'spec_helper'

describe 'ceilometer::config' do

  let :params do
    { :ceilometer_config  => {
                              'api/host' => { 'value' => '0.0.0.0'},
                              'api/port' => { 'value' => '8777'},
                             },
    }
  end

    it 'with [api] options ceilometer_config ' do
      is_expected.to contain_ceilometer_config('api/host').with_value('0.0.0.0')
      is_expected.to contain_ceilometer_config('api/port').with_value('8777')
    end

  describe 'with [rpc_notifier2] options ceilometer_config' do
    before do
      params.merge!({
        :ceilometer_config => { 'rpc_notifier2/topics' => { 'value' => 'notifications'},},
      })
    end
    it 'should configure rpc_notifier2 topics correctly' do
      is_expected.to contain_ceilometer_config('rpc_notifier2/topics').with_value('notifications')
    end

  end
end
