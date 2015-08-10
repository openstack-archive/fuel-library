require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/ntp-server.pp'

external_ntp = Noop.hiera('external_ntp')

describe manifest do
  shared_examples 'catalog' do
    it 'class ntp should contain ntp servers list' do
      should contain_class('ntp').with(
        'servers' => external_ntp
      )
    end
  end

  test_ubuntu_and_centos manifest
end

