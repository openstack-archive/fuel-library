require 'spec_helper'

describe 'swift::proxy::dlo' do

  let :facts do
    {}
  end

  let :pre_condition do
    'class { "concat::setup": }
    concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/36_swift_dlo"
  end

  describe "when using default parameters" do
    it 'should build the fragment with correct parameters' do
      verify_contents(catalogue, fragment_file,
        [
          '[filter:dlo]',
          'use = egg:swift#dlo',
          'rate_limit_after_segment = 10',
          'rate_limit_segments_per_sec = 1',
          'max_get_time = 86400',
        ]
      )
    end
  end

  describe "when overriding default parameters" do
    let :params do
      {
        :rate_limit_after_segment    => '30',
        :rate_limit_segments_per_sec => '5',
        :max_get_time                => '6400',
      }
    end
    it 'should build the fragment with correct parameters' do
      verify_contents(catalogue, fragment_file,
        [
          '[filter:dlo]',
          'use = egg:swift#dlo',
          'rate_limit_after_segment = 30',
          'rate_limit_segments_per_sec = 5',
          'max_get_time = 6400',
        ]
      )
    end
  end

end
