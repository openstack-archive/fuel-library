require 'spec_helper'

describe 'swift::test_file' do

  let :default_params do
    {:password => 'foo'}
  end

  describe 'with defaults' do

    let :params do
      default_params
    end

    it 'should create a reasonable test file' do
      verify_contents(catalogue, '/tmp/swift_test_file.rb',
        [
          'proxy_local_net_ip="127.0.0.1"',
          "user='openstack:admin'",
          "password='foo'"
        ]
      )
    end

  end

  describe 'when overridding' do

    let :params do
      default_params.merge({
        :auth_server => '127.0.0.2',
        :tenant      => 'tenant',
        :user        => 'user',
        :password    => 'password'
      })
    end

    it 'should create a configured test file' do
      verify_contents(catalogue, '/tmp/swift_test_file.rb',
        [
          'proxy_local_net_ip="127.0.0.2"',
          "user='tenant:user'",
          "password='password'"
        ]
      )
    end

  end
end
