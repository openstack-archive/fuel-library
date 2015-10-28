require 'spec_helper'
require 'shared-examples'
manifest = 'api-proxy/api-proxy.pp'

describe manifest do

  shared_examples 'catalog' do
    let(:master_ip) do
      Noop.hiera('master_ip')
    end

    let(:max_header_size) do
      Noop.hiera('max_header_size', '81900')
    end

    it {
      should contain_service('httpd').with(
           'hasrestart' => true,
           'restart'    => 'sleep 30 && apachectl graceful || apachectl restart'
      )
    }

    it 'should delcare osnailyfacter::apache_api_proxy' do
      expect(subject).to contain_class('osnailyfacter::apache_api_proxy').with(
        'master_ip'       => master_ip,
        'max_header_size' => max_header_size,
      )
    end

    include_examples 'saved_catalog', ['class[apache]', 'apache::vhost[apache_api_proxy]', 'firewall[007 tinyproxy]']

  end

  test_ubuntu_and_centos manifest
end
