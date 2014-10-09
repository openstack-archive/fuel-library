require 'spec_helper'

describe 'swift::proxy::ceilometer' do

  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/concat',
      :osfamily => 'Debian'
    }
  end

  let :pre_condition do
    'class { "concat::setup": }
     concat { "/etc/swift/proxy-server.conf": }
     class { "ssh::server::install": }
     class { "swift":
        swift_hash_suffix => "dummy"
     }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/33_swift_ceilometer"
  end

  it { should contain_file(fragment_file).with_content(/[filter:ceilometer]/) }
  it { should contain_file(fragment_file).with_content(/use = egg:ceilometer#swift/) }
  it { should contain_concat__fragment('swift_ceilometer').with_require('Class[::Ceilometer]') }
  it { should contain_user('swift').with_groups('ceilometer') }

end
