require 'spec_helper'

describe 'swift::proxy::staticweb' do

  let :facts do
    {}
  end

  let :pre_condition do
    'class { "concat::setup": }
     concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/32_swift-proxy-staticweb"
  end

  it { is_expected.to contain_file(fragment_file).with_content(/[filter:staticweb]/) }
  it { is_expected.to contain_file(fragment_file).with_content(/use = egg:swift#staticweb/) }

end
