require 'spec_helper'

describe 'haproxy::config' do
  let(:title) { 'tyler' }
  let(:facts) {{ :ipaddress => '1.1.1.1' }}
  context "when only one port is provided" do
    let(:params) do
      { :name  => 'croy',
        :ports => '18140'
      }
    end

    it { should contain_concat__fragment('croy_config_block').with(
      'order'   => '20',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\nlisten croy 1.1.1.1:18140\n  balance  roundrobin\n  option  tcplog\n  option  ssl-hello-chk\n"
    ) }
  end
  context "when an array of ports is provided" do
    let(:params) do
      { :name      => 'apache',
        :listen_ip => '23.23.23.23',
        :ports     => [
          '80',
          '443',
        ]
      }
    end

    it { should contain_concat__fragment('apache_config_block').with(
      'order'   => '20',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\nlisten apache 23.23.23.23:80,23.23.23.23:443\n  balance  roundrobin\n  option  tcplog\n  option  ssl-hello-chk\n"
    ) }
  end
end
