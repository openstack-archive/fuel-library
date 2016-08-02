require 'spec_helper'

describe 'fuel::keystone', :type => :class do
  context 'on supported platform' do
    let(:facts) {{
      :osfamily               => 'RedHat',
      :lsbdistid              => 'CentOS',
      :operatingsystem        => 'CentOS',
      :operatingsystemrelease => '7.2',
      :processorcount         => 48,
    }}
    context 'with default parameters' do
      describe 'limits keystone workers' do
        it {
          should contain_class('keystone').with(
            :public_workers => 16,
            :admin_workers  => 16
          )
        }
        it "creates 'keystone' vhost" do
          is_expected.to contain_class("keystone::wsgi::apache").with(
            :public_port            => '5000',
            :admin_port             => '35357',
            :ssl                    => false,
            :priority               => '05',
            :threads                => 3,
            :vhost_custom_fragment  => 'LimitRequestFieldSize 81900',
            :workers                => 1,
            :access_log_format      => 'forwarded',
          )
        end
      end

    end

  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
        let(:facts) { facts.merge!(@default_facts) }
      it_configures "keystone configuration"
    end
  end
end
