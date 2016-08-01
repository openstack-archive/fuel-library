require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/openrc_generate.pp'

describe manifest do

  shared_examples 'catalog' do

    let(:auth_suffix) { Noop.puppet_function 'pick', keystone_hash['auth_suffix'], '/' }

    let(:public_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'keystone','public','protocol','http' }

    let(:public_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'keystone','public','hostname',[public_vip] }

    let(:internal_url) { "#{internal_auth_protocol}://#{internal_auth_address}:5000" }

    operator_user_hash = Noop.hiera_structure 'operator_user', {}

    service_user_hash = Noop.hiera_structure 'operator_user', {}

    operator_user_name = operator_user_hash['name'] || 'fueladmin'

    service_user_name = service_user_hash['name'] || 'fuel'

    it 'should create osnailyfacter::credentials_file for root user with proper authentication URL' do
      should contain_osnailyfacter__credentials_file('/root/openrc').with(
        'auth_url'        => "#{internal_url}#{auth_suffix}",
      )
    end

    it 'should create osnailyfacter::credentials_file for operator user with proper authentication URL, owner, group and path' do
      should contain_osnailyfacter__credentials_file("#{operator_user_homedir}/openrc").with(
        'auth_url'        => "#{internal_url}#{auth_suffix}",
        'owner'           => "#{operator_user_name}",
        'group'           => "#{operator_user_name}",
      )
    end

    it 'should create osnailyfacter::credentials_file for service user with proper authentication URL, owner, group and path' do
      should contain_osnailyfacter__credentials_file("#{service_user_homedir}/openrc").with(
        'auth_url'        => "#{internal_url}#{auth_suffix}",
        'owner'           => "#{service_user_name}",
        'group'           => "#{service_user_name}",
      )
    end
  end

  test_ubuntu_and_centos manifest
end

