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

  let(:disabled_public_ssl_hash) do
    {
     'horizon' => false,
     'services' => false,
     'cert_source' => 'self_signed',
     'cert_data' => {
        'content' => 'somedataaboutyourkeypair'
     },
     'hostname' => 'disabled.public.fuel.local'
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

  context 'when both hashes is empty' do
    context 'for public endpoints' do
      it 'should get data from default values for horizon' do
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'usage', false).and_return(false)
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'usage', true).and_return(true)
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'usage', 'just a string').and_return('just a string')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'usage', ['an array value']).and_return('an array value')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'usage', ['', 'an array value']).and_return('an array value')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'usage', [true]).and_return(true)
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'usage', ['', true]).and_return(true)
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'usage', ['', false]).and_return(false)
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'usage', [true, false]).and_return(true)
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'usage', [false, true]).and_return(false)
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'hostname', 'horizon.fuel.local').and_return('horizon.fuel.local')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'hostname', ['horizon.fuel.local']).and_return('horizon.fuel.local')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'hostname', ['', 'horizon.fuel.local']).and_return('horizon.fuel.local')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'hostname', [nil, 'horizon.fuel.local']).and_return('horizon.fuel.local')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'hostname', ['horizon.fuel.local', 'second.fuel.local']).and_return('horizon.fuel.local')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'path', '/var/lib/somewhere').and_return('/var/lib/somewhere')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'protocol', 'http').and_return('http')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'protocol', 'https').and_return('https')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'protocol', ['https']).and_return('https')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'protocol', ['https', 'http']).and_return('https')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'protocol', ['', 'http']).and_return('http')
        is_expected.to run.with_params({}, {}, 'horizon', 'public', 'protocol', [nil, 'https']).and_return('https')
      end
      it 'should get data from default values for other services' do
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'usage', false).and_return(false)
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'usage', true).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'usage', 'just a string').and_return('just a string')
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'usage', ['an array value']).and_return('an array value')
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'usage', ['', 'an array value']).and_return('an array value')
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'usage', [true]).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'usage', ['', true]).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'usage', ['', false]).and_return(false)
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'usage', [true, false]).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'usage', [false, true]).and_return(false)
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'hostname', ['keystone.fuel.local']).and_return('keystone.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'hostname', ['', 'keystone.fuel.local']).and_return('keystone.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'hostname', [nil, 'keystone.fuel.local']).and_return('keystone.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'hostname', ['keystone.fuel.local', 'second.fuel.local']).and_return('keystone.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'path', '/var/lib/somewhere').and_return('/var/lib/somewhere')
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'protocol', 'http').and_return('http')
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'protocol', 'https').and_return('https')
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'protocol', ['', 'https']).and_return('https')
        is_expected.to run.with_params({}, {}, 'keystone', 'public', 'protocol', [nil, 'https']).and_return('https')
      end
    end
    context 'for non-public endpoints' do
      it 'should get data from default values for non-public endpoints' do

        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'usage', false).and_return(false)
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'usage', true).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'usage', 'just a string').and_return('just a string')
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'usage', ['an array value']).and_return('an array value')
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'usage', ['', 'an array value']).and_return('an array value')
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'usage', [true]).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'usage', ['', true]).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'usage', ['', false]).and_return(false)
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'usage', [true, false]).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'usage', [false, true]).and_return(false)
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'hostname', ['keystone.internal.fuel.local']).and_return('keystone.internal.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'hostname', ['', 'keystone.internal.fuel.local']).and_return('keystone.internal.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'hostname', [nil, 'keystone.internal.fuel.local']).and_return('keystone.internal.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'hostname', ['keystone.internal.fuel.local', 'second.fuel.local']).and_return('keystone.internal.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'path', '/var/lib/astute/haproxy/internal_keystone.pem').and_return('/var/lib/astute/haproxy/internal_keystone.pem')
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'protocol', 'http').and_return('http')
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'protocol', 'https').and_return('https')
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'protocol', ['', 'https']).and_return('https')
        is_expected.to run.with_params({}, {}, 'keystone', 'internal', 'protocol', [nil, 'https']).and_return('https')

        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'usage', false).and_return(false)
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'usage', true).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'usage', 'just a string').and_return('just a string')
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'usage', ['an array value']).and_return('an array value')
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'usage', ['', 'an array value']).and_return('an array value')
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'usage', [true]).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'usage', ['', true]).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'usage', ['', false]).and_return(false)
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'usage', [true, false]).and_return(true)
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'usage', [false, true]).and_return(false)
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'hostname', ['keystone.admin.fuel.local']).and_return('keystone.admin.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'hostname', ['', 'keystone.admin.fuel.local']).and_return('keystone.admin.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'hostname', [nil, 'keystone.admin.fuel.local']).and_return('keystone.admin.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'hostname', ['keystone.admin.fuel.local', 'second.fuel.local']).and_return('keystone.admin.fuel.local')
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'path', '/var/lib/astute/haproxy/admin_keystone.pem').and_return('/var/lib/astute/haproxy/admin_keystone.pem')
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'protocol', 'http').and_return('http')
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'protocol', 'https').and_return('https')
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'protocol', ['', 'https']).and_return('https')
        is_expected.to run.with_params({}, {}, 'keystone', 'admin', 'protocol', [nil, 'https']).and_return('https')
      end
    end
  end

  context 'when first hash is empty' do
    context 'for public endpoints' do
      it 'should get data from auxilary hash for horizon' do
        is_expected.to run.with_params({}, public_ssl_hash, 'horizon', 'public', 'usage', false).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'horizon', 'public', 'protocol', 'http').and_return('https')
        is_expected.to run.with_params({}, public_ssl_hash, 'horizon', 'public', 'hostname', 'internal.fuel.local').and_return('public.fuel.local')
        is_expected.to run.with_params({}, public_ssl_hash, 'horizon', 'public', 'path', '/root').and_return('/var/lib/astute/haproxy/public_haproxy.pem')

        is_expected.to run.with_params({}, disabled_public_ssl_hash, 'horizon', 'public', 'usage', true).and_return(false)
        is_expected.to run.with_params({}, disabled_public_ssl_hash, 'horizon', 'public', 'protocol', 'https').and_return('http')
        is_expected.to run.with_params({}, disabled_public_ssl_hash, 'horizon', 'public', 'path', '/root').and_return('/var/lib/astute/haproxy/public_haproxy.pem')
      end
      it 'should get data from auxilary hash for other services' do
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'public', 'usage', false).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'public', 'protocol', 'http').and_return('https')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'public', 'hostname', 'internal.fuel.local').and_return('public.fuel.local')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'public', 'path', '/root').and_return('/var/lib/astute/haproxy/public_haproxy.pem')

        is_expected.to run.with_params({}, disabled_public_ssl_hash, 'keystone', 'public', 'usage', true).and_return(false)
        is_expected.to run.with_params({}, disabled_public_ssl_hash, 'keystone', 'public', 'protocol', 'https').and_return('http')
        is_expected.to run.with_params({}, disabled_public_ssl_hash, 'keystone', 'public', 'path', '/root').and_return('/var/lib/astute/haproxy/public_haproxy.pem')
      end
      it 'should get data from default values for protocol when ssl disabled for public' do
        is_expected.to run.with_params({}, disabled_public_ssl_hash, 'horizon', 'public', 'hostname', '10.7.7.7').and_return('10.7.7.7')
        is_expected.to run.with_params({}, disabled_public_ssl_hash, 'keystone', 'public', 'hostname', '10.7.7.7').and_return('10.7.7.7')
      end
    end
    context 'for non-public endpoints' do
      it 'should get data from default values for non-public endpoints' do
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', true).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'protocol', 'https').and_return('https')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'hostname', ['keystone.internal.fuel.local']).and_return('keystone.internal.fuel.local')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'path', '/var/lib/astute/haproxy/internal_keystone.pem').and_return('/var/lib/astute/haproxy/internal_keystone.pem')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', true).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'protocol', 'https').and_return('https')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'hostname', ['keystone.admin.fuel.local']).and_return('keystone.admin.fuel.local')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'path', '/var/lib/astute/haproxy/admin_keystone.pem').and_return('/var/lib/astute/haproxy/admin_keystone.pem')

        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', false).and_return(false)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', true).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', 'just a string').and_return('just a string')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', ['an array value']).and_return('an array value')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', ['', 'an array value']).and_return('an array value')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', [true]).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', ['', true]).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', ['', false]).and_return(false)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', [true, false]).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'usage', [false, true]).and_return(false)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'hostname', ['keystone.fuel.local']).and_return('keystone.fuel.local')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'path', '/var/lib/somewhere').and_return('/var/lib/somewhere')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'protocol', 'http').and_return('http')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'internal', 'protocol', 'https').and_return('https')

        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', false).and_return(false)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', true).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', 'just a string').and_return('just a string')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', ['an array value']).and_return('an array value')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', ['', 'an array value']).and_return('an array value')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', [true]).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', ['', true]).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', ['', false]).and_return(false)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', [true, false]).and_return(true)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'usage', [false, true]).and_return(false)
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'hostname', ['keystone.fuel.local']).and_return('keystone.fuel.local')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'path', '/var/lib/somewhere').and_return('/var/lib/somewhere')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'protocol', 'http').and_return('http')
        is_expected.to run.with_params({}, public_ssl_hash, 'keystone', 'admin', 'protocol', 'https').and_return('https')
      end
    end
  end

  context 'when second hash is empty' do
    # there shouldn't be such case, cause first hash ALWAYS override second one
  end

  context 'when both hashes provided' do
    context 'for public endpoints' do
      it 'should get data from first hash for horizon' do
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'horizon', 'public', 'usage', false).and_return(true)
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'horizon', 'public', 'protocol', 'http').and_return('https')
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'horizon', 'public', 'hostname', ['no default']).and_return('horizon.public.fuel.local')
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'horizon', 'public', 'path', ['no default']).and_return('/var/lib/astute/haproxy/public_horizon.pem')

        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'horizon', 'public', 'usage', false).and_return(true)
        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'horizon', 'public', 'protocol', 'http').and_return('https')
        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'horizon', 'public', 'hostname', ['no default']).and_return('horizon.public.fuel.local')
        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'horizon', 'public', 'path', ['no default']).and_return('/var/lib/astute/haproxy/public_horizon.pem')
      end
      it 'should get data from first hash for other services' do
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'keystone', 'public', 'usage', false).and_return(true)
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'keystone', 'public', 'protocol', 'http').and_return('https')
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'keystone', 'public', 'hostname', ['no default']).and_return('keystone.public.fuel.local')
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'keystone', 'public', 'path', ['no default']).and_return('/var/lib/astute/haproxy/public_keystone.pem')

        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'keystone', 'public', 'usage', false).and_return(true)
        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'keystone', 'public', 'protocol', 'http').and_return('https')
        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'keystone', 'public', 'hostname', ['no default']).and_return('keystone.public.fuel.local')
        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'keystone', 'public', 'path', ['no default']).and_return('/var/lib/astute/haproxy/public_keystone.pem')
      end
    end

    context 'for non-public endpoints' do
      it 'should get data from first hash for other services' do
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'keystone', 'internal', 'usage', false).and_return(true)
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'keystone', 'internal', 'protocol', 'http').and_return('https')
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'keystone', 'internal', 'hostname', ['no default']).and_return('keystone.internal.fuel.local')
        is_expected.to run.with_params(use_ssl_hash, disabled_public_ssl_hash, 'keystone', 'internal', 'path', ['no default']).and_return('/var/lib/astute/haproxy/internal_keystone.pem')

        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'keystone', 'internal', 'usage', false).and_return(true)
        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'keystone', 'internal', 'protocol', 'http').and_return('https')
        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'keystone', 'internal', 'hostname', ['no default']).and_return('keystone.internal.fuel.local')
        is_expected.to run.with_params(use_ssl_hash, public_ssl_hash, 'keystone', 'internal', 'path', ['no default']).and_return('/var/lib/astute/haproxy/internal_keystone.pem')
      end
    end
  end
end
