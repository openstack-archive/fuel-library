require 'spec_helper'

describe 'swift::proxy::swift3' do

  let :facts do
    { :osfamily        => 'Debian',
      :operatingsystem => 'Ubuntu' }
  end

  let :pre_condition do
    'class { "concat::setup": }
     concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/27_swift_swift3"
  end

  it { is_expected.to contain_file(fragment_file).with_content(/[filter:swift3]/) }
  it { is_expected.to contain_file(fragment_file).with_content(/use = egg:swift3#swift3/) }

end
