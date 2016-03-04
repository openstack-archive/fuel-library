require 'spec_helper'

describe 'osnailyfacter::allocate_hugepages' do

  context 'with defined hugepages' do
    let :title do
      { 'count' => 512, 'numa_id' => 0, 'size' => 2048 }
    end

    it { is_expected.to contain_file('/sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages').with(
      :ensure  => 'file',
      :content => '512',
    ) }
  end

end
