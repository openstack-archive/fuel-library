require "spec_helper"

describe "fuel::keystone" do

  let :global_facts do
    {
      :processorcount => 42,
    }
  end

  shared_examples_for "keystone configuration" do

    context "with default params" do

      it "ensures httpd confdir for ports-configs" do
        is_expected.to contain_file('/etc/httpd/conf.ports.d/').with(
          :ensure => 'directory',
        )
      end

      it "configures 'apache' class" do
        is_expected.to contain_class("apache").with(
            :server_signature => "Off",
            :trace_enable     => "Off",
            :purge_configs    => false,
            :purge_vhost_dir  => false,
            :default_vhost    => false,
            :conf_template    => 'fuel/httpd.conf.erb',
            :ports_file       => '/etc/httpd/conf.ports.d/keystone.conf',
        )
      end

      it "creates 'keystone' vhost" do
        is_expected.to contain_class("keystone::wsgi::apache").with(
          :public_port            => '5000',
          :admin_port             => '35357',
          :ssl                    => false,
          :priority               => '05',
          :threads                => 3,
          :vhost_custom_fragment  => 'LimitRequestFieldSize 81900',
          :workers                => 6,
          :access_log_format      => 'forwarded',
        )
      end

    end

  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it_configures "keystone configuration"
    end
  end

end

