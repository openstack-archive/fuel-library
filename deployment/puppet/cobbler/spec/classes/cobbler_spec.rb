require 'spec_helper'

describe 'cobbler' do

  let(:default_params) { {
      :server => facts[:ipaddress],
      :production => 'prod',
      :domain_name => 'local',
      :name_server => facts[:ipaddress],
      :next_server => facts[:ipaddress],
      :dns_upstream => ['8.8.8.8'],
      :dns_domain => 'domain.tld',
      :dns_search => 'domain.tld',
      :dhcp_start_address => '10.0.0.201',
      :dhcp_end_address => '10.0.0.254',
      :dhcp_netmask => '255.255.255.0',
      :dhcp_gateway => facts[:ipaddress],
      :dhcp_ipaddress => '127.0.0.1',
      :cobbler_user => 'cobbler',
      :cobbler_password => 'cobbler',
      :pxetimeout => 0,
  } }

  shared_examples_for 'cobbler configuration' do
    let :params do
      default_params
    end

    context 'with default params' do
      let :params do
        default_params.merge!({})
      end

      it { is_expected.to contain_class('cobbler') }

      it { is_expected.to contain_class('cobbler::apache') }

      it { is_expected.to contain_class('cobbler::packages') }

      it { is_expected.to contain_class('cobbler::selinux') }

      it { is_expected.to contain_class('cobbler::iptables') }

      it do
        is_expected.to contain_class('cobbler::server').with(
            :domain_name => params[:domain_name],
            :production => params[:production],
            :dns_upstream => params[:dns_upstream],
            :dns_domain => params[:dns_domain],
            :dns_search => params[:dns_search],
            :dhcp_gateway => params[:dhcp_gateway],
            :extra_admins_net => params[:extra_admins_nets],
        )
      end

      it do
        is_expected.to contain_cobbler_digest_user(params[:cobbler_user]).with(
            :password => params[:cobbler_password],
        )
      end

      it { is_expected.to contain_file_line('Change debug level in cobbler') }
    end

  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it_configures "cobbler configuration"
    end
  end

end
