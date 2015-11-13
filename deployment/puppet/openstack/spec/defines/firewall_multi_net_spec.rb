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
        :port      => '22',
        :proto     => 'tcp',
        :source    => '10.20.0.0/24',
      )
    end
  end
end
