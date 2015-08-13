require 'spec_helper'
require 'shared-examples'
manifest = 'tools/tools.pp'

describe manifest do
  shared_examples 'catalog' do
    it "should contain ssh host keygen exec" do
      should contain_exec('host-ssh-keygen').with(
        'command' => 'ssh-keygen -A'
      )
    end
  end

  test_ubuntu_and_centos manifest
end

