require 'spec_helper'

describe 'swift::proxy::healthcheck' do

  let :facts do
    {}
  end

  let :pre_condition do
    'class { "concat::setup": }
     concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/25_swift_healthcheck"
  end

  it { is_expected.to contain_file(fragment_file).with_content(/[filter:healthcheck]/) }
  it { is_expected.to contain_file(fragment_file).with_content(/use = egg:swift#healthcheck/) }

end
