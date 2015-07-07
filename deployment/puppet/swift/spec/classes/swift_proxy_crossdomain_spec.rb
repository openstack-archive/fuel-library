require 'spec_helper'

describe 'swift::proxy::crossdomain' do

  let :facts do
    {}
  end

  let :pre_condition do
    'class { "concat::setup": }
    concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/35_swift_crossdomain"
  end

  describe "when using default parameters" do
    it 'should build the fragment with correct parameters' do
      verify_contents(catalogue, fragment_file,
        [
          '[filter:crossdomain]',
          'use = egg:swift#crossdomain',
          'cross_domain_policy = <allow-access-from domain="*" secure="false" />',
        ]
      )
    end
  end

  describe "when overriding default parameters" do
    let :params do
      {
        :cross_domain_policy => '<allow-access-from domain="xml-fragment-in-ini-file.so.wrong" secure="true" />
<allow-access-from domain="*" secure="false" />',
      }
    end
    it 'should build the fragment with correct parameters' do
      verify_contents(catalogue, fragment_file,
        [
          '[filter:crossdomain]',
          'use = egg:swift#crossdomain',
          'cross_domain_policy = <allow-access-from domain="xml-fragment-in-ini-file.so.wrong" secure="true" />',
          '<allow-access-from domain="*" secure="false" />',
        ]
      )
    end
  end

end
