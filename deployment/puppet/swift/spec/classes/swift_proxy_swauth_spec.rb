require 'spec_helper'

describe 'swift::proxy::swauth' do

  let :facts do
    {}
  end

  let :pre_condition do
    'class { "concat::setup": }
     concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/20_swift_proxy_swauth"
  end

  it { is_expected.to contain_package('python-swauth').with_ensure('present') }

  it { is_expected.to contain_file(fragment_file).with_content(/[filter:swauth]/) }
  it { is_expected.to contain_file(fragment_file).with_content(/use = egg:swauth#swauth/) }

  describe 'with defaults' do

    it { is_expected.to contain_file(fragment_file).with_content(/default_swift_cluster = local#127\.0\.0\.1/) }
    it { is_expected.to contain_file(fragment_file).with_content(/super_admin_key = swauthkey/) }

  end

  describe 'with overridden parameters' do

    let :params do
      {:swauth_endpoint => '10.0.0.1',
       :swauth_super_admin_key => 'foo',
       :package_ensure => 'latest' }
    end

    it { is_expected.to contain_file(fragment_file).with_content(/default_swift_cluster = local#10\.0\.0\.1/) }
    it { is_expected.to contain_file(fragment_file).with_content(/super_admin_key = foo/) }
    it { is_expected.to contain_package('python-swauth').with_ensure('latest') }

  end

end

