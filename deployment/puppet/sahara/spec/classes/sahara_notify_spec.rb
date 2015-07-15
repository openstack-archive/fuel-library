require 'spec_helper'
describe 'sahara::notify' do
  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  describe 'when defaults with notify enabled' do
    let :params do
      {:enable_notifications => 'true'}
    end
    it { is_expected.to contain_sahara_config('DEFAULT/control_exchange').with_value('openstack') }
    it { is_expected.to contain_sahara_config('DEFAULT/notification_driver').with_value('messaging') }
    it { is_expected.to contain_sahara_config('DEFAULT/notification_topics').with_value('notifications') }
    it { is_expected.to contain_sahara_config('DEFAULT/notification_level').with_value('INFO') }
  end

  describe 'when passing params' do
    let :params do
      {
        :enable_notifications => 'true',
        :control_exchange     => 'openstack',
        :notification_driver  => 'messaging',
        :notification_topics  => 'notifications',
        :notification_level   => 'INFO',
      }
    it { is_expected.to contain_sahara_config('DEFAULT/control_exchange').with_value('openstack') }
    it { is_expected.to contain_sahara_config('DEFAULT/notification_driver').with_value('messaging') }
    it { is_expected.to contain_sahara_config('DEFAULT/notification_topics').with_value('notifications') }
    it { is_expected.to contain_sahara_config('DEFAULT/notification_level').with_value('INFO') }
    end
  end

end
