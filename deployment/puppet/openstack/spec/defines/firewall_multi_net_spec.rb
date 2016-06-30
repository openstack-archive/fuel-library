require 'spec_helper'

describe 'openstack::firewall::multi_net' do
  let(:default_params) { {
    :source_nets => [],
  } }

  context 'with ssh rule config' do
    let(:title) { '020 ssh' }

    let(:params) { {
      :action      => 'accept',
      :port        => '22',
      :proto       => 'tcp',
      :source_nets => ['10.20.0.0/24'],
    } }

    it 'contains ssh firewall rule' do
      should contain_firewall("020 ssh from 10.20.0.0/24").with(
        :action    => 'accept',
        :dport      => '22',
        :proto     => 'tcp',
        :source    => '10.20.0.0/24',
      )
    end
  end

  context 'with icmp block rule config' do
    let(:title) { '299 icmp' }

    let(:params) { {
      :action      => 'drop',
      :chain       => 'INPUT',
      :proto       => 'icmp',
      :source_nets => ['120.0.0.0/8', '12.34.56.78/32'],
    } }

    it 'contains ssh firewall rule' do
      should contain_firewall("299 icmp from 120.0.0.0/8").with(
        :action    => 'drop',
        :chain     => 'INPUT',
        :proto     => 'icmp',
        :source    => '120.0.0.0/8',
      )
      should contain_firewall("299 icmp from 12.34.56.78/32").with(
        :action    => 'drop',
        :chain     => 'INPUT',
        :proto     => 'icmp',
        :source    => '12.34.56.78/32',
      )
    end
  end
end
