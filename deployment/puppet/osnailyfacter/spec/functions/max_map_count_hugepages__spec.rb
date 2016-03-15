require 'spec_helper'

describe 'max_map_count_hugepages' do

  let :input_data do
    [
      { 'count' => 512, 'numa_id' => 0, 'size' => 2048 },
      { 'count' => 8, 'numa_id' => 1, 'size' => 1048576 }
    ]
  end

  let :output do
    66570
  end

  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params().and_raise_error(ArgumentError, /Wrong number of arguments given/) }
  it { is_expected.to run.with_params('string').and_raise_error(Puppet::ParseError, /expected a hash with/) }
  it { is_expected.to run.with_params({}).and_raise_error(Puppet::ParseError, /expected a hash with/) }

  it { is_expected.to run.with_params([{'numa_id' => 0}]).and_raise_error(Puppet::ParseError, /expected a hash with/) }

  it { is_expected.to run.with_params(input_data).and_return(output) }
  it { is_expected.to run.with_params([]).and_return(65530) }

end
