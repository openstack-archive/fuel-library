require 'spec_helper'

describe 'glance::cache::pruner' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  it 'configures a cron' do
    should contain_cron('glance-cache-pruner').with(
      :command     => 'glance-cache-pruner',
      :environment => 'PATH=/bin:/usr/bin:/usr/sbin',
      :user        => 'glance',
      :minute      => '*/30',
      :hour        => '*',
      :monthday    => '*',
      :month       => '*',
      :weekday     => '*'
    )
  end
end
