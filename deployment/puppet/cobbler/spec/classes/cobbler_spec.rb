require 'spec_helper'

describe 'cobbler' do

  let(:default_params) { {
    :server => facts[:ipaddress],
    :production => 'prod',
    :domain_name => 'local',
    :name_server => facts[:ipaddress],
    :next_server => facts[:ipaddress],
    :dns_upstream => '8.8.8.8',
    :dns_domain   => 'domain.tld',
    :dns_search   => 'domain.tld',
    :dhcp_start_address => '10.0.0.201',
    :dhcp_end_address   => '10.0.0.254',
    :dhcp_netmask       => '255.255.255.0',
    :dhcp_gateway       => facts[:ipaddress],
    :dhcp_interface     => 'eth0',
    :cobbler_user       => 'cobbler',
    :cobbler_password   => 'cobbler',
    :pxetimeout         => 0,
  } }

  shared_examples_for 'cobbler configuration' do
    let :params do
      default_params
    end


    context 'with default params' do
      let :params do
        default_params.merge!({})
      end

      it 'configures with the default params' do
        should contain_class('cobbler')
        should contain_class('cobbler::packages')
        should contain_class('cobbler::selinux')
        should contain_class('cobbler::iptables')
        should contain_class('cobbler::snippets')
        should contain_class('cobbler::server').with(
          :domain_name      => params[:domain_name],
          :production       => params[:production],
          :dns_upstream     => params[:dns_upstream],
          :dns_domain       => params[:dns_domain],
          :dns_search       => params[:dns_search],
          :dhcp_gateway     => params[:dhcp_gateway],
          :extra_admins_net => params[:extra_admins_nets])
        should contain_cobbler_digest_user(params[:cobbler_user]).with(
          :password => params[:cobbler_password])
        should contain_file_line('Change debug level in cobbler')
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'Debian',
        :operatingsystem => 'Debian',
      })
    end

    it_configures 'cobbler configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemrelease => '7'
      })
    end

    it_configures 'cobbler configuration'
  end

end

