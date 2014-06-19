require 'spec_helper'

describe 'cinder::quota' do

  describe 'with default parameters' do
    it 'contains default values' do
      should contain_cinder_config('DEFAULT/quota_volumes').with(
        :value => 10)
      should contain_cinder_config('DEFAULT/quota_snapshots').with(
        :value => 10)
      should contain_cinder_config('DEFAULT/quota_gigabytes').with(
        :value => 1000)
      should contain_cinder_config('DEFAULT/quota_driver').with(
        :value => 'cinder.quota.DbQuotaDriver')
    end
  end

  describe 'with overridden parameters' do
    let :params do
      { :quota_volumes => 1000,
        :quota_snapshots => 1000,
        :quota_gigabytes => 100000 }
    end
    it 'contains overrided values' do
      should contain_cinder_config('DEFAULT/quota_volumes').with(
        :value => 1000)
      should contain_cinder_config('DEFAULT/quota_snapshots').with(
        :value => 1000)
      should contain_cinder_config('DEFAULT/quota_gigabytes').with(
        :value => 100000)
      should contain_cinder_config('DEFAULT/quota_driver').with(
        :value => 'cinder.quota.DbQuotaDriver')
    end
  end
end
