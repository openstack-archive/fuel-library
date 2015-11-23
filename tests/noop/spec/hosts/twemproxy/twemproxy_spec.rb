require 'spec_helper'
require 'shared-examples'
manifest = 'twemproxy/twemproxy.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'contain twemproxy class' do
      should contain_class('twemproxy')
    end

  end

  test_ubuntu_and_centos manifest
end
