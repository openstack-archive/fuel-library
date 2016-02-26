require 'spec_helper'

describe 'get_ssl_property' do

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:get_ssl_property)
    scope.method(function_name)
  end

  let(:public_ssl_hash) do
    {
     'horizon' => true,
     'services' => true,
     'cert_source' => 'self_signed',
     'cert_data' => {
        'content' => 'somedataaboutyourkeypair'
     },
     'hostname' => 'public.fuel.local'
    }
  end

  let(:public_ssl_hash_disabled) do
    {
     'horizon' => false,
     'services' => false,
     'cert_source' => 'self_signed',
     'cert_data' => {
        'content' => 'somedataaboutyourkeypair'
     },
     'hostname' => 'public.fuel.local'
    }
  end

  let(:use_ssl_hash) do
    {
      'horizon' => true,
      'horizon_public' => true,
      'horizon_public_hostname' => 'horizon.public.fuel.local',
      'horizon_public_usercert' => true,
      'horizon_public_certdata' => 'somethinglikeacertificateforhorizon',
      'keystone' => true,
      'keystone_public' => true,
      'keystone_public_ip' => '10.10.10.10',
      'keystone_public_hostname' => 'keystone.public.fuel.local',
      'keystone_public_usercert' => true,
      'keystone_public_certdata' => 'somethinglikeacertificateforkeystone',
      'keystone_internal' => true,
      'keystone_internal_ip' => '20.20.20.20',
      'keystone_internal_hostname' => 'keystone.internal.fuel.local',
      'keystone_internal_usercert' => true,
      'keystone_internal_certdata' => 'somethinglikeacertificateforkeystone',
      'keystone_admin' => true,
      'keystone_admin_ip' => '30.30.30.30',
      'keystone_admin_hostname' => 'keystone.admin.fuel.local',
      'keystone_admin_usercert' => true,
      'keystone_admin_certdata' => 'somethinglikeacertificateforkeystone',
    }
  end

  context 'when wrong data provided' do
    it 'should exist' do
      is_expected.not_to eq(nil)
    end

    it 'should fail if first argument is not hash' do
      is_expected.to run.with_params(10, public_ssl_hash, 'test', 'test', 'test', false).and_raise_error(Puppet::Error, /hash as a first argument/)
    end

    it 'should fail if second argument is not hash' do
      is_expected.to run.with_params(use_ssl_hash, 10, 'test', 'test', 'test', false).and_raise_error(Puppet::Error, /hash as a second argument/)
    end

    it 'should fail if third argument is empty' do
      is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, '', 'test', 'test', false).and_raise_error(Puppet::Error, /'name' for service/)
    end

    it 'should fail if fourth argument is empty' do
      is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'test', '', 'test', false).and_raise_error(Puppet::Error, /'type' for service/)
    end

    it 'should fail if fifth argument is empty' do
      is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'test', 'test', '', false).and_raise_error(Puppet::Error, /'type' for resource/)
    end

    it 'should fail if fifth argument is wrong' do
      is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'test', 'test', 'wrong', false).and_raise_error(Puppet::Error, /should choose/)
    end

  end

  context 'when first hash is empty' do
    it 'should get data from auxilary hash for public endpoints' do
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'public', 'usage', false).and_return(true)
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'public', 'protocol', 'http').and_return('https')
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'public', 'hostname', 'internal.fuel.local').and_return('public.fuel.local')
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'public', 'path', '/root').and_return('/var/lib/astute/haproxy/public_haproxy.pem')
    end

    it 'should get data from default values for non-public endpoints when empty hashes provided' do
      is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'usage', true).and_return(true)
      is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'protocol', 'https').and_return('https')
      is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'hostname', ['keystone.internal.fuel.local']).and_return('keystone.internal.fuel.local')
      is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'path', '/var/lib/astute/haproxy/internal_keystone.pem').and_return('/var/lib/astute/haproxy/internal_keystone.pem')
      is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'usage', true).and_return(true)
      is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'protocol', 'https').and_return('https')
      is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'hostname', ['keystone.admin.fuel.local']).and_return('keystone.admin.fuel.local')
      is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'path', '/var/lib/astute/haproxy/admin_keystone.pem').and_return('/var/lib/astute/haproxy/admin_keystone.pem')
    end

    it 'should get data from default values for non-public endpoints when public_ssl hash provided' do
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', true).and_return(true)
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'protocol', 'https').and_return('https')
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'hostname', ['keystone.internal.fuel.local']).and_return('keystone.internal.fuel.local')
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'path', '/var/lib/astute/haproxy/internal_keystone.pem').and_return('/var/lib/astute/haproxy/internal_keystone.pem')
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', true).and_return(true)
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'protocol', 'https').and_return('https')
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'hostname', ['keystone.admin.fuel.local']).and_return('keystone.admin.fuel.local')
      is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'path', '/var/lib/astute/haproxy/admin_keystone.pem').and_return('/var/lib/astute/haproxy/admin_keystone.pem')
    end

    it 'should get data from first hash when it has data and both hashes provided' do
      is_expected.to run.with_params(use_ssl_hash, public_ssl_hash_disabled, 'keystone', 'public', 'usage', false).and_return(true)
      is_expected.to run.with_params(use_ssl_hash, public_ssl_hash_disabled, 'keystone', 'public', 'protocol', 'http').and_return('https')
      is_expected.to run.with_params(use_ssl_hash, public_ssl_hash_disabled, 'keystone', 'public', 'hostname', ['no default']).and_return('keystone.public.fuel.local')
      is_expected.to run.with_params(use_ssl_hash, public_ssl_hash_disabled, 'keystone', 'public', 'path', ['no default']).and_return('/var/lib/astute/haproxy/public_keystone.pem')
    end

  end
end
