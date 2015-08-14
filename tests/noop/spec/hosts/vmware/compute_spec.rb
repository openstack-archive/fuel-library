require 'spec_helper'
require 'shared-examples'
manifest = 'vmware/compute.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should have cache_prefix option set to $host' do
      should contain_file('/etc/nova/nova-compute.conf').with_content(
        %r{\n\s*cache_prefix=\$host\n}
      )
    end
  end
  test_ubuntu_and_centos manifest
end

