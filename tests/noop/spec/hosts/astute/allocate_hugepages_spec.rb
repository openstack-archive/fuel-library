require 'spec_helper'
require 'shared-examples'
manifest = 'astute/allocate_hugepages.pp'

describe manifest do
  shared_examples 'catalog' do
    hugepages = Noop.hiera_array 'hugepages', false

    if hugepages
      it "should allocate defined hugepages" do
        hugepages.each do |hp|
          nr_hps = "/sys/devices/system/node/node#{hp['numa_id']}/hugepages/hugepages-#{hp['size']}kB/nr_hugepages"
          should contain_file(nr_hps).with(
            :ensure  => 'file',
            :content => "#{hp['count']}"
          )
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
