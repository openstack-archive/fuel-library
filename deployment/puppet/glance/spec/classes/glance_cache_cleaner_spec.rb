require 'spec_helper'

describe 'glance::cache::cleaner' do

  shared_examples_for 'glance cache cleaner' do

    context 'when default parameters' do

      it 'configures a cron' do
         should contain_cron('glance-cache-cleaner').with(
          :command     => 'glance-cache-cleaner ',
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

    context 'when overriding parameters' do
      let :params do
        {
          :minute           => 59,
          :hour             => 23,
          :monthday         => '1',
          :month            => '2',
          :weekday          => '3',
          :command_options  => '--config-dir /etc/glance/',
        }
      end
      it 'configures a cron' do
        should contain_cron('glance-cache-cleaner').with(
          :command     => 'glance-cache-cleaner --config-dir /etc/glance/',
          :environment => 'PATH=/bin:/usr/bin:/usr/sbin',
          :user        => 'glance',
          :minute      => 59,
          :hour        => 23,
          :monthday    => '1',
          :month       => '2',
          :weekday     => '3'
        )
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    include_examples 'glance cache cleaner'
    it { should contain_cron('glance-cache-cleaner').with(:require     => 'Package[glance-api]')}
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    include_examples 'glance cache cleaner'
    it { should contain_cron('glance-cache-cleaner').with(:require     => 'Package[openstack-glance]')}
  end

end
