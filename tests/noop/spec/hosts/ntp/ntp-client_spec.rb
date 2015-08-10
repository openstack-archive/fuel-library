require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/ntp-client.pp'

ntp_servers = Noop.hiera('ntp_servers')

describe manifest do
  shared_examples 'catalog' do
    it 'class ntp should contain ntp servers list' do
      should contain_class('ntp').with(
        'servers' => ntp_servers
      )
    end
  end

  test_ubuntu_and_centos manifest
end

