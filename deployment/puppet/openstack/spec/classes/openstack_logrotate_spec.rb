require 'spec_helper'

describe 'openstack::logrotate' do

  let(:default_params) { {
    :role     => 'client',
    :rotation => 'weekly',
    :keep     => '4',
    :minsize  => '30M',
    :maxsize  => '100M',
    :debug    => false,
  } }

  let(:params) { {} }

  shared_examples_for 'logrotate configuration' do
    let :p do
      default_params.merge(params)
    end

    it 'contains openstack::logrotate' do
      should contain_class('openstack::logrotate')
    end

    context 'with default params' do
      it 'configures with the default params' do
        should contain_file('/etc/logrotate.d/fuel.nodaily')
        should contain_file('/etc/logrotate.d/puppet')
        should contain_file('/etc/logrotate.d/upstart').with_ensure('absent')
        ['logrotate-tabooext',
         'logrotate-compress',
         'logrotate-delaycompress',
         'logrotate-minsize',
         'logrotate-maxsize',].each do |item|
          should contain_file_line(item)
        end
        should contain_cron('fuel-logrotate').with_minute('*/30')
      end
    end

    context 'with debug = true' do
      let :params do
        { :debug => true }
      end

      it 'configures debug' do
        should contain_cron('fuel-logrotate').with_minute('*/10')
      end
    end
  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it_configures 'logrotate configuration'
    end
  end

end

