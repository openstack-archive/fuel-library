require 'spec_helper'

describe 'swift::proxy::authtoken' do

  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/concat',
    }
  end

  let :pre_condition do
    '
      include concat::setup
      concat { "/etc/swift/proxy-server.conf": }
    '
  end

  describe 'when using the default signing directory' do
    let :file_defaults do
      {
        :mode    => '0700',
        :owner   => 'swift',
        :group   => 'swift',
      }
    end
    it {should contain_file('/var/cache/swift').with(
      {:ensure => 'directory'}.merge(file_defaults)
    )}
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/22_swift_authtoken"
  end

  describe "when using default parameters" do
    it 'should build the fragment with correct parameters' do
      verify_contents(subject, fragment_file,
        [
          '[filter:authtoken]',
          'log_name = swift',
          'signing_dir = /var/cache/swift',
          'paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory',
          'auth_host = 127.0.0.1',
          'auth_port = 35357',
          'auth_protocol = http',
          'auth_uri = http://127.0.0.1:5000',
          'admin_tenant_name = services',
          'admin_user = swift',
          'admin_password = password',
          'delay_auth_decision = 1',
          'cache = swift.cache',
          'include_service_catalog = False'
        ]
      )
    end
  end

  describe "when overriding admin_token" do
    let :params do
      {
        :admin_token => 'ADMINTOKEN'
      }
    end

    it 'should build the fragment with correct parameters' do
      verify_contents(subject, fragment_file,
        [
          '[filter:authtoken]',
          'log_name = swift',
          'signing_dir = /var/cache/swift',
          'paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory',
          'auth_host = 127.0.0.1',
          'auth_port = 35357',
          'auth_protocol = http',
          'auth_uri = http://127.0.0.1:5000',
          'admin_token = ADMINTOKEN',
          'delay_auth_decision = 1',
          'cache = swift.cache',
          'include_service_catalog = False'
        ]
      )
    end
  end

  describe "when overriding parameters" do
    let :params do
      {
        :auth_host           => 'some.host',
        :auth_port           => '443',
        :auth_protocol       => 'https',
        :auth_admin_prefix   => '/keystone/admin',
        :admin_tenant_name   => 'admin',
        :admin_user          => 'swiftuser',
        :admin_password      => 'swiftpassword',
        :cache               => 'foo',
        :delay_auth_decision => '0',
        :signing_dir         => '/home/swift/keystone-signing'
      }
    end

    it 'should build the fragment with correct parameters' do
      verify_contents(subject, fragment_file,
        [
          '[filter:authtoken]',
          'log_name = swift',
          'signing_dir = /home/swift/keystone-signing',
          'paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory',
          'auth_host = some.host',
          'auth_port = 443',
          'auth_protocol = https',
          'auth_admin_prefix = /keystone/admin',
          'auth_uri = https://some.host:5000',
          'admin_tenant_name = admin',
          'admin_user = swiftuser',
          'admin_password = swiftpassword',
          'delay_auth_decision = 0',
          'cache = foo',
          'include_service_catalog = False'
        ]
      )
    end
  end

  describe 'when overriding auth_uri' do
    let :params do
      { :auth_uri => 'http://public.host/keystone/main' }
    end

    it { should contain_file(fragment_file).with_content(/auth_uri = http:\/\/public.host\/keystone\/main/)}
  end

  [
    'keystone',
    'keystone/',
    '/keystone/',
    '/keystone/admin/',
    'keystone/admin/',
    'keystone/admin'
  ].each do |auth_admin_prefix|
    describe "when overriding auth_admin_prefix with incorrect value #{auth_admin_prefix}" do
      let :params do
        { :auth_admin_prefix => auth_admin_prefix }
      end

      it { expect { should contain_file(fragment_file).with_content(/auth_admin_prefix = #{auth_admin_prefix}/) }.to \
        raise_error(Puppet::Error, /validate_re\(\): "#{auth_admin_prefix}" does not match/) }
    end
  end



end
