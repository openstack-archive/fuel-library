# ROLE: primary-controller
# ROLE: controller
# R_N: neut_gre.generate_vms ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/openrc_delete.pp'

describe manifest do

  shared_examples 'catalog' do
    openrc = '/root/openrc'

    it "should remove #{openrc} file" do
      should contain_file(openrc).with('ensure' => 'absent')
    end
  end

  test_ubuntu_and_centos manifest
end
