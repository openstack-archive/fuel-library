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
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'cinder' => '{"blkio":{"blkio.weight":500, "blkio.test":800}, "memory":{"memory.soft_limit_in_bytes":700}}',
        'keystone' => '{"cpu":{"cpu.shares":70}}'
      }
    }

    let(:result) {
      {
        'cinder' => {
          'blkio' => {
            'blkio.weight' => 500,
            'blkio.test' => 800
          },
          'memory' => {
            'memory.soft_limit_in_bytes' => 700 * 1024 * 1024
          },
        },
        'keystone' => {
          'cpu' => {
            'cpu.shares' => 70
          }
        }
      }
    }

    it 'should transform hash with simple values' do
      should run.with_params(sample).and_return(result)
    end

  end

  context "transform hash with expression" do

    let(:sample) {
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'neutron' => '{"memory":{"memory.soft_limit_in_bytes":"%50, 300, 700"}}'
      }
    }

    let(:result) {
      {
        'neutron' => {
          'memory' => {
            'memory.soft_limit_in_bytes' => 512 * 1024 * 1024
          }
        }
      }
    }

    it 'should transform hash including expression to compute' do
      should run.with_params(sample).and_return(result)
    end

  end

  context "transform hash with expression and return integer value" do

    let(:sample) {
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'neutron' => '{"memory":{"memory.soft_limit_in_bytes":"%51, 300, 700"}}'
      }
    }

    let(:result) {
      {
        'neutron' => {
          'memory' => {
            'memory.soft_limit_in_bytes' => (522.24 * 1024 * 1024).to_i
          }
        }
      }
    }

    it 'should transform hash including expression to compute and return int' do
      should run.with_params(sample).and_return(result)
    end

  end

  context "transform hash with expression including extra whitespaces" do

    let(:sample) {
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'neutron' => '{"memory":{"memory.soft_limit_in_bytes":"%51,      300,      700"}}'
      }
    }

    let(:result) {
      {
        'neutron' => {
          'memory' => {
            'memory.soft_limit_in_bytes' => (522.24 * 1024 * 1024).to_i
          }
        }
      }
    }

    it 'should transform hash including expression to compute with whitespaces' do
      should run.with_params(sample).and_return(result)
    end

  end

  context "transform hash with empty service's settings" do

    let(:sample) {
      {
        'metadata' => {
          'always_editable' => true,
          'group' => 'general',
          'label' => 'Cgroups',
          'weight' => 50
        },
        'nova' => '{"memory":{"memory.soft_limit_in_bytes":700}}',
        'cinder-api'  => '{}'
      }
    }

    let(:result) {
      {
        'nova' => {
          'memory' => {
            'memory.soft_limit_in_bytes' => 700 * 1024 * 1024
          }
        }
      }
    }

    it 'should transform hash with empty service settings' do
      should run.with_params(sample).and_return(result)
    end

  end

  context "wrong JSON format" do

    let(:sample) {
      {
        'neutron' => '{"memory":{"memory.soft_limit_in_bytes":"%50, 300, 700"}}}}'
      }
    }

    let(:result) {
      {}
    }

    it 'should raise if settings have wrong JSON format' do
      is_expected.to run.with_params(sample).and_raise_error(RuntimeError, /JSON parsing  error/)
    end

  end

  context "converting memory to megabytes only for bytes value" do

    let(:sample) {
      {
        'neutron' => '{"memory":{"memory.swappiness": 10}}',
        'nova' => '{"hugetlb":{"hugetlb.16GB.limit_in_bytes": 10}}'
      }
    }

    let(:result) {
      {
        'neutron' => {
          'memory' => {
            'memory.swappiness' => 10
          }
        },
        'nova' => {
          'hugetlb' => {
            'hugetlb.16GB.limit_in_bytes' => 10 * 1024 * 1024
          }
        }
      }
    }

    it 'should convert memory values only for bytes values' do
      should run.with_params(sample).and_return(result)
    end

  end

  context "service's cgroup settings are not a HASH" do

    let(:sample) {
      {
        'neutron' => '{"memory": 28}'
      }
    }

    it 'should raise if group option is not a Hash' do
      is_expected.to run.with_params(sample).and_raise_error(RuntimeError, /options is not a HASH instance/)
    end

  end

  context "cgroup limit is not an integer" do

    let(:sample) {
      {
        'neutron' => '{"memory":{"memory.soft_limit_in_bytes":"test"}}'
      }
    }

    it 'should raise if limit value is not an integer or template' do
      is_expected.to run.with_params(sample).and_raise_error(RuntimeError, /has wrong value/)
    end

  end

end
