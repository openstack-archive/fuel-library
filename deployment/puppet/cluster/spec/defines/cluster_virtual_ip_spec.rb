require 'spec_helper'

describe 'cluster::virtual_ip', type: :define do

  let(:title) do
    'my_ip'
  end

  context 'with only basic parameters' do
    let(:params) do
      {
          bridge: 'br0',
          ip: '192.168.0.2',
          ns_veth: 'tst',
          gateway: '192.168.0.1',
      }
    end

    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_cluster__virtual_ip('my_ip') }

    resource_parameters = {
        :ensure => 'present',
        :primitive_class => 'ocf',
        :primitive_type => 'ns_IPaddr2',
        :primitive_provider => 'fuel',
        :parameters => {
            'bridge' => 'br0',
            'ip' => '192.168.0.2',
            'gateway' => '192.168.0.1',
            'cidr_netmask' => '24',
            'iflabel' => 'ka',
            'ns' => 'haproxy',
            'ns_veth' => 'tst',
        },
        :operations => {
            'monitor' => {
                'interval' => '5',
                'timeout' => '20',
            },
            'start' => {
                'interval' => '0',
                'timeout' => '30',
            },
            'stop' => {
                'interval' => '0',
                'timeout' => '30',
            }
        },
        :metadata => {
            'migration-threshold' => '3',
            'failure-timeout' => '60',
            'resource-stickiness' => '1',
        }
    }

    it { is_expected.to contain_pcmk_resource('vip__my_ip').with(resource_parameters) }

  end

end