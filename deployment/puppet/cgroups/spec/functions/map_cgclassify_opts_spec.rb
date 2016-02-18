require 'spec_helper'

describe 'map_cgclassify_opts' do

  let :input_data do
    {
      'nova-api' => {
        'memory' => {
          'memory.soft_limit_in_bytes' => 500,
        },
        'cpu' => {
          'cpu.shares' => 60,
        },
      },
      'neutron-server' => {
        'memory' => {
          'memory.soft_limit_in_bytes' => 500,
          'memory.limit_in_bytes' => 100,
        }
      }
    }
  end

  let :mapped_options do
    {
      'nova-api' => {
        :cgroup => ['memory:/nova-api', 'cpu:/nova-api']
      },
      'neutron-server' => {
        :cgroup => ['memory:/neutron-server']
      }
    }
  end

  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params().and_raise_error(ArgumentError, /Wrong number of arguments given/) }
  it { is_expected.to run.with_params('string').and_raise_error(Puppet::ParseError, /expected a hash/) }

  it { is_expected.to run.with_params({}).and_return({}) }
  it { is_expected.to run.with_params({'service-x' => ['blkio', 0]}).and_return({}) }
  it { is_expected.to run.with_params({'service-z' => {}}).and_return({}) }

  it { is_expected.to run.with_params(input_data).and_return(mapped_options) }

end
