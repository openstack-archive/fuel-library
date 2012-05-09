require 'spec_helper'

describe 'haproxy::config' do
  let(:title) { 'tyler' }
  let(:facts) {{ :ipaddress => '1.1.1.1' }}
  let(:params) do
    { :name            => 'croy',
      :virtual_ip_port => '18140'
    }
  end

  it { should contain_concat__fragment('croy_config_block').with(
    'order'   => '20',
    'target'  => '/etc/haproxy/haproxy.cfg',
    'content' => "\nlisten croy 1.1.1.1:18140\n  balance  roundrobin\n  option  tcplog\n  option  ssl-hello-chk\n"
    ) }
end