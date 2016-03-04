require 'spec_helper'

describe 'map_sysfs_hugepages' do

  let :input_data do
    [
      { 'count' => 512, 'numa_id' => 0, 'size' => 2048 },
      { 'count' => 8, 'numa_id' => 1, 'size' => 1048576 }
    ]
  end

  let :mapped_options do
    {
      'node0/hugepages/hugepages-2048kB' => 512,
      'node1/hugepages/hugepages-1048576kB' => 8,
      'default' => 0
    }
  end

  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params().and_raise_error(ArgumentError, /Wrong number of arguments given/) }
  it { is_expected.to run.with_params('string').and_raise_error(Puppet::ParseError, /expected an array/) }

  it { is_expected.to run.with_params([{'count' => 512, 'numa_id' => 0}]).and_raise_error(Puppet::ParseError, /required all options/) }
  it { is_expected.to run.with_params([{'count' => 64, 'size' => 2048}]).and_raise_error(Puppet::ParseError, /required all options/) }

  it { is_expected.to run.with_params(input_data).and_return(mapped_options) }

end
