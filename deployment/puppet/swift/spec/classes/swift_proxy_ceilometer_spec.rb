require 'spec_helper'

describe 'swift::proxy::ceilometer' do

  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :pre_condition do
    'class { "concat::setup": }
     concat { "/etc/swift/proxy-server.conf": }
     class { "swift":
        swift_hash_suffix => "dummy"
     }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/33_swift_ceilometer"
  end

  it { is_expected.to contain_file(fragment_file).with_content(/[filter:ceilometer]/) }
  it { is_expected.to contain_file(fragment_file).with_content(/use = egg:ceilometer#swift/) }
  if Puppet.version.to_f < 4.0
    it { is_expected.to contain_concat__fragment('swift_ceilometer').with_require('Class[::Ceilometer]')}
  else
    it { is_expected.to contain_concat__fragment('swift_ceilometer').with_require('Class[Ceilometer]')}
  end
  it { is_expected.to contain_user('swift').with_groups('ceilometer') }
  it { is_expected.to contain_file('/var/log/ceilometer/swift-proxy-server.log').with(:owner => 'swift', :group => 'swift', :mode => '0664') }

end
