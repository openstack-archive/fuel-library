require 'spec_helper'

describe 'swift::proxy::s3token' do

  let :facts do
    {}
  end

  let :pre_condition do
    'class { "concat::setup": }
     concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/28_swift_s3token"
  end

  it { is_expected.to contain_class('keystone::python') }

  describe "when using default parameters" do
    it 'should build the fragment with correct parameters' do
      verify_contents(catalogue, fragment_file,
        [
          '[filter:s3token]',
          'paste.filter_factory = keystonemiddleware.s3_token:filter_factory',
          'auth_port = 35357',
          'auth_protocol = http',
          'auth_host = 127.0.0.1'
        ]
      )
    end
  end

  describe "when overriding default parameters" do
    let :params do
      {
          :auth_port     => 4212,
          :auth_protocol => 'https',
          :auth_host     => '1.2.3.4'
      }
    end
    it 'should build the fragment with correct parameters' do
      verify_contents(catalogue, fragment_file,
        [
          '[filter:s3token]',
          'paste.filter_factory = keystonemiddleware.s3_token:filter_factory',
          'auth_port = 4212',
          'auth_protocol = https',
          'auth_host = 1.2.3.4'
        ]
      )
    end
  end

end
