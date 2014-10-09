require 'spec_helper'

describe 'swift::dispersion' do

  let :default_params do
    { :auth_url      => 'http://127.0.0.1:5000/v2.0/',
      :auth_user     => 'dispersion',
      :auth_tenant   => 'services',
      :auth_pass     => 'dispersion_password',
      :auth_version  => '2.0',
      :endpoint_type => 'publicURL',
      :swift_dir     => '/etc/swift',
      :coverage      => 1,
      :retries       => 5,
      :concurrency   => 25,
      :dump_json     => 'no' }
  end

  let :pre_condition do
    "class { 'swift': swift_hash_suffix => 'string' }"
  end

  let :facts do
    { :osfamily => 'Debian' }
  end

  let :params do
    {}
  end

  it { should contain_file('/etc/swift/dispersion.conf').with(
    :ensure  => 'present',
    :owner   => 'swift',
    :group   => 'swift',
    :mode    => '0660',
    :require => 'Package[swift]')
  }

  shared_examples 'swift::dispersion' do
    let (:p) { default_params.merge!(params) }

    it 'depends on swift package' do
      should contain_package('swift').with_before(/Swift_dispersion_config\[.+\]/)
    end

    it 'configures dispersion.conf' do
      should contain_swift_dispersion_config(
        'dispersion/auth_url').with_value(p[:auth_url])
      should contain_swift_dispersion_config(
        'dispersion/auth_version').with_value(p[:auth_version])
      should contain_swift_dispersion_config(
        'dispersion/auth_user').with_value("#{p[:auth_tenant]}:#{p[:auth_user]}")
      should contain_swift_dispersion_config(
        'dispersion/auth_key').with_value(p[:auth_pass])
      should contain_swift_dispersion_config(
        'dispersion/endpoint_type').with_value(p[:endpoint_type])
      should contain_swift_dispersion_config(
        'dispersion/swift_dir').with_value(p[:swift_dir])
      should contain_swift_dispersion_config(
        'dispersion/dispersion_coverage').with_value(p[:coverage])
      should contain_swift_dispersion_config(
        'dispersion/retries').with_value(p[:retries])
      should contain_swift_dispersion_config(
        'dispersion/concurrency').with_value(p[:concurrency])
      should contain_swift_dispersion_config(
        'dispersion/dump_json').with_value(p[:dump_json])
    end

    it 'triggers swift-dispersion-populate' do
      should contain_exec('swift-dispersion-populate').with(
        :path      => ['/bin', '/usr/bin'],
        :subscribe => 'File[/etc/swift/dispersion.conf]',
        :onlyif    => "swift -A #{p[:auth_url]} -U #{p[:auth_tenant]}:#{p[:auth_user]} -K #{p[:auth_pass]} -V #{p[:auth_version]} stat | grep 'Account: '",
        :unless    => "swift -A #{p[:auth_url]} -U #{p[:auth_tenant]}:#{p[:auth_user]} -K #{p[:auth_pass]} -V #{p[:auth_version]} list | grep dispersion_",
        :require => 'Package[swiftclient]'
      )
    end
  end

  describe 'with default parameters' do
    include_examples 'swift::dispersion'
  end

  describe 'when parameters are overriden' do
    before do
      params.merge!(
        :auth_url      => 'https://10.0.0.10:7000/auth/v8.0/',
        :auth_user     => 'foo',
        :auth_tenant   => 'bar',
        :auth_pass     => 'dummy',
        :auth_version  => '1.0',
        :endpoint_type => 'internalURL',
        :swift_dir     => '/usr/local/etc/swift',
        :coverage      => 42,
        :retries       => 51,
        :concurrency   => 4682,
        :dump_json     => 'yes'
      )
    end

    include_examples 'swift::dispersion'
  end
end
