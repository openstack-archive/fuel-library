require 'spec_helper'

describe 'swift::storage::filter::healthcheck' do
  let :title do
    'dummy'
  end

  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/concat'
    }
  end

  let :pre_condition do
    'class { "concat::setup": }
     concat { "/etc/swift/dummy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_dummy-server.conf/fragments/25_swift_healthcheck_dummy"
  end

it 'should build the fragment with correct content' do
  verify_contents(subject, fragment_file,
    [
      '[filter:healthcheck]',
      'use = egg:swift#healthcheck'
    ]
  )
end

end
