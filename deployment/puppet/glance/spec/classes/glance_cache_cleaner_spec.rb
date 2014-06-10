require 'spec_helper'

describe 'glance::cache::cleaner' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  it 'configures a cron' do
    should contain_cron('glance-cache-cleaner').with(
      :command     => 'glance-cache-cleaner',
      :environment => 'PATH=/bin:/usr/bin:/usr/sbin',
      :user        => 'glance',
      :minute      => 1,
      :hour        => 0,
      :monthday    => '*',
      :month       => '*',
      :weekday     => '*'
    )
  end
end
