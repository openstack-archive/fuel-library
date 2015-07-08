require 'spec_helper'

describe 'nova::cron::archive_deleted_rows' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  it 'configures a cron' do
    is_expected.to contain_cron('nova-manage db archive_deleted_rows').with(
      :command     => 'nova-manage db archive_deleted_rows --max_rows 100 >>/var/log/nova/nova-rowsflush.log 2>&1',
      :environment => 'PATH=/bin:/usr/bin:/usr/sbin SHELL=/bin/sh',
      :user        => 'nova',
      :minute      => 1,
      :hour        => 0,
      :monthday    => '*',
      :month       => '*',
      :weekday     => '*',
      :require     => 'Package[nova-common]',
    )
  end
end
