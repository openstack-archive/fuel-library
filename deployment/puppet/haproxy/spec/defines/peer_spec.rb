require 'spec_helper'

describe 'haproxy::peer' do
  let(:title) { 'dero' }
  let(:facts) do
    {
      :ipaddress => '1.1.1.1',
      :hostname  => 'dero',
    }
  end

  context 'with a single peer' do
    let(:params) do
      {
        :peers_name => 'tyler',
        :port       => 1024,
      }
    end

    it { should contain_concat__fragment('peers-tyler-dero').with(
      'order'   => '30-peers-01-tyler-dero',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "  peer dero 1.1.1.1:1024\n"
    ) }
  end

  context 'remove a peer' do
    let(:params) do
      {
        :peers_name => 'tyler',
        :port       => 1024,
        :ensure     => 'absent'
      }
    end

    it { should contain_concat__fragment('peers-tyler-dero').with(
      'ensure' => 'absent'
    ) }
  end
end
