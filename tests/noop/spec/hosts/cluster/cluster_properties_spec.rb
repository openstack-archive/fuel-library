require 'spec_helper'
require 'shared-examples'
manifest = 'cluster/cluster_properties.pp'

describe manifest do
  shared_examples 'catalog' do
    cluster_recheck_interval = Noop.hiera('cluster_recheck_interval', '190s')

    it { should contain_cs_property('no-quorum-policy').with({
      'ensure'   => 'present',
      'provider' => 'crm',
      })
    }
    it { should contain_cs_property('stonith-enabled').with({
      'ensure'   => 'present',
      'provider' => 'crm',
      'value'    => 'false'
      })
    }
    it { should contain_cs_property('start-failure-is-fatal').with({
      'ensure'   => 'present',
      'provider' => 'crm',
      'value'    => 'false'
      })
    }
    it { should contain_cs_property('symmetric-cluster').with({
      'ensure'   => 'present',
      'provider' => 'crm',
      'value'    => 'false'
      })
    }
    it { should contain_cs_property('cluster-recheck-interval').with({
      'ensure'   => 'present',
      'provider' => 'crm',
      'value'    => cluster_recheck_interval
      })
    }
  end
  test_ubuntu_and_centos manifest
end
