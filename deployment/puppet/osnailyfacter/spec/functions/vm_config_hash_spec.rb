require 'puppet'
require 'spec_helper'

describe 'vm_config_hash' do
  it { should run.with_params(nil).and_return({})}
  it { should run.with_params([]).and_return({})}
  it { should run.with_params('a').and_return({})}

  vms = [
      {
          'id' => '1',
          'cpu' => '10',
          'mem' => '20',
      },
      {
          'id' => '2',
          'cpu' => '20',
          'mem' => '40',
      }
  ]

  vm_hash = {
      '1' => {
          'details' => {
              'id' => '1',
              'cpu' => '10',
              'mem' => '20',
          },
      },
      '2' => {
          'details' => {
              'id' => '2',
              'cpu' => '20',
              'mem' => '40',
          },
      },
  }

  it { should run.with_params(vms).and_return(vm_hash) }
end
