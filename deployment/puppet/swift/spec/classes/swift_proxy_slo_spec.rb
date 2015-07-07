require 'spec_helper'

describe 'swift::proxy::slo' do

  let :facts do
    {}
  end

  let :pre_condition do
    'class { "concat::setup": }
    concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/35_swift_slo"
  end

  describe "when using default parameters" do
    it 'should build the fragment with correct parameters' do
      verify_contents(catalogue, fragment_file,
        [
          '[filter:slo]',
          'use = egg:swift#slo',
          'max_manifest_segments = 1000',
          'max_manifest_size = 2097152',
          'min_segment_size = 1048576',
          'rate_limit_after_segment = 10',
          'rate_limit_segments_per_sec = 0',
          'max_get_time = 86400',
        ]
      )
    end
  end

  describe "when overriding default parameters" do
    let :params do
      {
        :max_manifest_segments     => '2000',
        :max_manifest_size         => '500000',
        :rate_limit_after_segment  => '30',
        :max_get_time              => '6400',
      }
    end
    it 'should build the fragment with correct parameters' do
      verify_contents(catalogue, fragment_file,
        [
          '[filter:slo]',
          'use = egg:swift#slo',
          'max_manifest_segments = 2000',
          'max_manifest_size = 500000',
          'rate_limit_after_segment = 30',
          'max_get_time = 6400',
        ]
      )
    end
  end

end
