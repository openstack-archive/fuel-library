require 'spec_helper'

describe 'keystone::cron::token_flush' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  describe 'with default parameters' do
    it 'configures a cron' do
      is_expected.to contain_cron('keystone-manage token_flush').with(
        :ensure      => 'present',
        :command     => 'keystone-manage token_flush >>/var/log/keystone/keystone-tokenflush.log 2>&1',
        :environment => 'PATH=/bin:/usr/bin:/usr/sbin SHELL=/bin/sh',
        :user        => 'keystone',
        :minute      => 1,
        :hour        => 0,
        :monthday    => '*',
        :month       => '*',
        :weekday     => '*'
      )
    end
  end

  describe 'when specifying a maxdelay param' do
    let :params do
      {
        :maxdelay => 600
      }
    end

    it 'configures a cron with delay' do
      is_expected.to contain_cron('keystone-manage token_flush').with(
        :ensure      => 'present',
        :command     => 'sleep `expr ${RANDOM} \\% 600`; keystone-manage token_flush >>/var/log/keystone/keystone-tokenflush.log 2>&1',
        :environment => 'PATH=/bin:/usr/bin:/usr/sbin SHELL=/bin/sh',
        :user        => 'keystone',
        :minute      => 1,
        :hour        => 0,
        :monthday    => '*',
        :month       => '*',
        :weekday     => '*'
      )
    end
  end

  describe 'when specifying a maxdelay param' do
    let :params do
      {
        :ensure => 'absent'
      }
    end

    it 'configures a cron with delay' do
      is_expected.to contain_cron('keystone-manage token_flush').with(
        :ensure      => 'absent',
        :command     => 'keystone-manage token_flush >>/var/log/keystone/keystone-tokenflush.log 2>&1',
        :environment => 'PATH=/bin:/usr/bin:/usr/sbin SHELL=/bin/sh',
        :user        => 'keystone',
        :minute      => 1,
        :hour        => 0,
        :monthday    => '*',
        :month       => '*',
        :weekday     => '*'
      )
    end
  end
end
