require 'spec_helper'

describe 'generate_cgclassify' do
  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params().and_raise_error(ArgumentError, /Wrong number of arguments given/) }

  context 'with input data/hash' do
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

    describe 'check calalogue out' do
      before { subject.call([input_data]) }

      {
        'nova-api' => {
          :ensure => :present,
          :cgroup => ['memory:/nova-api', 'cpu:/nova-api'],
        },
        'neutron-server' => {
          :ensure => :present,
          :cgroup => ['memory:/neutron-server'],
        },
      }.each do |service, resource_opts|
        # this lambda is required due to strangeness within rspec-puppet's expectation handling
        it { expect(lambda { catalogue }).to contain_cgclassify(service).with(
            resource_opts,
        ) }
      end
    end

    describe 'check calalogue out with defaults' do
      before { subject.call([input_data, {:sticky => true, :ensure => :present}]) }

      {
        'nova-api' => {
          :ensure => :present,
          :cgroup => ['memory:/nova-api', 'cpu:/nova-api'],
          :sticky => true,
        },
        'neutron-server' => {
          :ensure => :present,
          :cgroup => ['memory:/neutron-server'],
          :sticky => true,
        },
      }.each do |service, resource_opts|
        # this lambda is required due to strangeness within rspec-puppet's expectation handling
        it { expect(lambda { catalogue }).to contain_cgclassify(service).with(
            resource_opts,
        ) }
      end
    end

  end
end
