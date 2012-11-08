require 'spec_helper'

describe 'swift::proxy::ratelimit' do

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
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/26_swift_ratelimit"
  end

  describe "when using default parameters" do
    it 'should build the fragment with correct parameters' do
      verify_contents(subject, fragment_file,
        [
          '[filter:ratelimit]',
          'use = egg:swift#ratelimit',
          'clock_accuracy = 1000',
          'max_sleep_time_seconds = 60',
          'log_sleep_time_seconds = 0',
          'rate_buffer_seconds = 5',
          'account_ratelimit = 0',
        ]
      )
    end
  end

  describe "when overriding default parameters" do
    let :params do
      {
        :clock_accuracy         => 9436,
        :max_sleep_time_seconds => 3600,
        :log_sleep_time_seconds => 42,
        :rate_buffer_seconds    => 51,
        :account_ratelimit      => 69
      }
    end
    it 'should build the fragment with correct parameters' do
      verify_contents(subject, fragment_file,
        [
          '[filter:ratelimit]',
          'use = egg:swift#ratelimit',
          'clock_accuracy = 9436',
          'max_sleep_time_seconds = 3600',
          'log_sleep_time_seconds = 42',
          'rate_buffer_seconds = 51',
          'account_ratelimit = 69',
        ]
      )
    end
  end

end
