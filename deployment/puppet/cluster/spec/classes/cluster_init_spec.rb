require 'spec_helper'

describe 'cluster' do

  let(:cluster_nodes) do
    {
        'node-5.test.domain.local' => {
            'id' => '5',
            'ip' => '192.168.0.5',
        },
        'node-9.test.domain.local' => {
            'id' => '9',
            'ip' => '192.168.0.4',
        }
    }
  end

  let(:facts) do
    {
        operatingsystem: 'Ubuntu',
        osfamily: 'Debian',
        operatingsystemrelease: '14.04',
    }
  end

  let(:params) do
    {
        cluster_nodes: cluster_nodes,
    }
  end

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_class('cluster') }

    it do
      parameters = {
          cluster_nodes: cluster_nodes,
      }

      is_expected.to contain_class('pacemaker::new').with(parameters)
    end

    it { is_expected.to contain_pacemaker_property('no-quorum-policy').with_value('ignore') }
    it { is_expected.to contain_pacemaker_property('stonith-enabled').with_value(false) }
    it { is_expected.to contain_pacemaker_property('start-failure-is-fatal').with_value(false) }
    it { is_expected.to contain_pacemaker_property('symmetric-cluster').with_value(false) }
    it { is_expected.to contain_pacemaker_property('cluster-recheck-interval').with_value('60') }

    it { is_expected.to contain_file('ocf-fuel-path') }

    it { is_expected.to contain_file('limits_conf') }

    it { is_expected.to contain_file('pcmk_uid_gid') }
  end

end

