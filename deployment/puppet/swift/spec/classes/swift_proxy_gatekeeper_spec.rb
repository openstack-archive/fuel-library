require 'spec_helper'

describe 'swift::proxy::gatekeeper' do

  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/concat'
    }
  end

  let :pre_condition do
    'class { "concat::setup": }
    concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/34_swift_gatekeeper"
  end

  describe "when using default parameters" do
    it 'should build the fragment with correct parameters' do
      verify_contents(subject, fragment_file,
        [
          '[filter:gatekeeper]',
          'use = egg:swift#gatekeeper',
          'set log_name = gatekeeper',
          'set log_facility = LOG_LOCAL0',
          'set log_level = INFO',
          'set log_headers = false',
          'set log_address = /dev/log',
        ]
      )
    end
  end

  describe "when overriding default parameters" do
    let :params do
      {
        :log_name         => 'newgatekeeper',
        :log_facility     => 'LOG_LOCAL2',
        :log_level        => 'WARN',
      }
    end
    it 'should build the fragment with correct parameters' do
      verify_contents(subject, fragment_file,
        [
          '[filter:gatekeeper]',
          'use = egg:swift#gatekeeper',
          'set log_name = newgatekeeper',
          'set log_facility = LOG_LOCAL2',
          'set log_level = WARN',
        ]
      )
    end
  end

end
