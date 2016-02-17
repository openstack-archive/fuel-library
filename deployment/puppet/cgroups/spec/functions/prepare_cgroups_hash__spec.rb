require 'spec_helper'

describe Puppet::Parser::Functions.function(:prepare_cgroups_hash) do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:prepare_cgroups_hash)
    scope.method(function_name)
  end

  it 'should exist' do
    subject == Puppet::Parser::Functions.function(:prepare_cgroups_hash)
  end

  Facter.stubs(:fact).with(:memorysize_mb).returns Facter.add(:memorysize_mb) { setcode { 1024 } }

  context "transform simple hash" do
    let(:sample) {
      {
        'cinder' => '{"blkio":{"blkio.weight":500}}',
        'keystone' => '{"cpu":{"cpu.shares":70}}'
      }
    }

    let(:result) {
      [
        {
          'cinder' => {
            'blkio' => {
              'blkio.weight' => 500
            }
          }
        },
        {
          'keystone' => {
            'cpu' => {
              'cpu.shares' => 70
            }
          }
        }
      ]
    }

    it 'should transform hash with simple values' do
      should run.with_params(sample).and_return(result)
    end

  end


  context "transform hash with expression" do

    let(:sample) {
      {
        'neutron' => '{"memory":{"memory.soft_limit_in_bytes":"%50, 300, 700"}}'
      }
    }

    let(:result) {
      [
       {
         'neutron' => {
           'memory' => {
             'memory.soft_limit_in_bytes' => 512
           }
         }
       }
      ]
    }

    it 'should transform hash including expression to compute' do
      should run.with_params(sample).and_return(result)
    end

  end

end
