require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig.pp'

describe manifest do
  shared_examples 'puppet catalogue' do
    it { should compile }
  end
  test_ubuntu_and_centos manifest
end

