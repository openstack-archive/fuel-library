require 'spec_helper'

describe 'remove_ovs_usage' do

  let(:input_without_transformations) {
    {
      'version' => 1.2,
      'transformations' => {},
    }
  }

  let(:output_without_transformations) {
    {
      'use_ovs' => false,
    }
  }

  let(:i_w_nonpatch) {
    {
      'version' => 1.2,
      'transformations' => [
        {
          'provider' => 'ovs',
          'action' => 'foo',
          'name' => 'bar',
        },
        {
          'provider' => 'dpdkovs',
          'bridge' => 'bridge-0',
          'action' => 'add-port',
          'name' => 'ethx',
        }
      ],
    }
  }

  let(:o_w_nonpatch) {
    {
      'use_ovs' => false,
      'network_scheme' => {
        'transformations' => [
          {
            'action' => 'override',
            'override' => 'bar',
            'provider' => 'lnx',
          },
          {
            'action' => 'override',
            'override' => 'ethx',
            'provider' => 'lnx',
          }
        ]
      }
    }
  }

  let(:i_w_patch) {
    {
      'version' => 1.2,
      'transformations' => [
        {
          'provider' => 'ovs',
          'action' => 'add-patch',
          'name' => 'bar',
          'bridges' => [
            'bridge-0',
            'bridge-1',
          ]
        }
      ],
    }
  }

  let(:o_w_patch) {
    {
      'use_ovs' => false,
      'network_scheme' => {
        'transformations' => [
          {
            'action' => 'override',
            'override' => 'patch-bridge-0:bridge-1',
            'provider' => 'lnx',
          }
        ]
      }
    }
  }

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should expect 1 argument' do
    is_expected.to run.with_params().and_raise_error(Puppet::ParseError)
    is_expected.to run.with_params(1, 2).and_raise_error(Puppet::ParseError)
  end

  it 'should expect a hash as given argument' do
    is_expected.to run.with_params('foo').and_raise_error(Puppet::ParseError)
  end

  it 'should return a hash with disabled ovs in any case' do
    is_expected.to run.with_params(input_without_transformations).and_return(output_without_transformations.to_yaml() + "\n")
  end

  it 'should return a proper hash when override action is not add-patch' do
    is_expected.to run.with_params(i_w_nonpatch).and_return(o_w_nonpatch.to_yaml() + "\n")
  end

  it 'should return a proper hash when override action is an add-patch' do
    is_expected.to run.with_params(i_w_patch).and_return(o_w_patch.to_yaml() + "\n")
  end
end
