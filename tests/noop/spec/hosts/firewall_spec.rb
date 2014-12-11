require 'spec_helper'
require File.join File.dirname(__FILE__), '../shared-examples'
manifest = 'firewall.pp'

describe manifest do
  shared_examples 'puppet catalogue' do
    it { should compile }
  end
  test_ubuntu_and_centos manifest
end

