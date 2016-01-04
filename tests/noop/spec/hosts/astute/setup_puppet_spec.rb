require 'spec_helper'
require 'shared-examples'
manifest = 'astute/setup_puppet.pp'

describe manifest do
  shared_examples 'catalog' do

    it "should disable stringify_facts" do
      should contain_ini_setting('disable stringify_facts').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppet/puppet.conf',
        'section' => 'main',
        'setting' => 'stringify_facts',
        'value'   => 'false',
      )
    end

  end
  test_ubuntu_and_centos manifest
end
