require 'spec_helper'
require 'shared-examples'
manifest = 'heat/heat.pp'

describe manifest do
  shared_examples 'catalog' do

    use_syslog = Noop.hiera 'use_syslog'

    it 'should set empty trusts_delegated_roles for heat authentication and engine' do
      should contain_class('heat::keystone::auth').with(
        'trusts_delegated_roles' => [],
      )
      should contain_class('heat::engine').with(
        'trusts_delegated_roles' => [],
      )
      should contain_heat_config('DEFAULT/trusts_delegated_roles').with(
        'value' => [],
      )
    end

    it 'should configure syslog rfc format for heat' do
      should contain_heat_config('DEFAULT/use_syslog_rfc_format').with(:value => use_syslog)
    end

    it 'should contain openstack::heat class with db_allowed_hosts parameter' do
      hostname = Noop.hostname
      db_allowed_hosts = [ '%', hostname ]
      should contain_class('heat::db::mysql').with('allowed_hosts' => db_allowed_hosts)
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

