require 'spec_helper'
require 'shared-examples'
manifest = 'pkg-proxy/pkg-proxy-del.pp'

describe manifest do

  shared_examples 'catalog' do

    it {
      if facts[:osfamily] == 'Debian'
        should contain_class('apt').with(
          'proxy_host' => nil,
          'proxy_port' => '8080',
        )
      end
    }

  end

  test_ubuntu_and_centos manifest
end

