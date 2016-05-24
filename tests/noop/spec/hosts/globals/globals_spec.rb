# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute
# ROLE: compute-vmware
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
require 'spec_helper'
require 'shared-examples'

manifest = 'globals/globals.pp'

describe manifest do

  shared_examples 'catalog' do
    it { is_expected.to contain_file '/etc/hiera/globals.yaml' }

    it 'should save the globals yaml file', :if => ENV['SPEC_UPDATE_GLOBALS'] do
      globals_yaml_content = Noop.resource_parameter_value self, 'file', '/etc/hiera/globals.yaml', 'content'
      raise 'Could not get globals file content!' unless globals_yaml_content
      Noop.write_file_globals globals_yaml_content
    end
  end

  test_ubuntu_and_centos manifest
end



