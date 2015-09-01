require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/ntp-server.pp'

describe manifest do
  shared_examples 'catalog' do

    it 'should disable monitor' do
      should contain_class('ntp').with('disable_monitor' => 'false')
    end

    test_ubuntu_and_centos manifest
  end
end
