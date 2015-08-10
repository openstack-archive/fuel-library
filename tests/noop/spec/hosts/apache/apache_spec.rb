require 'spec_helper'
require 'shared-examples'
manifest = 'apache/apache.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should execute apache class with given parameters' do
      should contain_class('apache').with(
        'mpm_module'       => 'false',
        'default_vhost'    => 'false',
        'server_tokens'    => 'Prod',
        'server_signature' => 'Off',
        'trace_enable'     => 'Off',
      )
    end
  end
  test_ubuntu_and_centos manifest
end
