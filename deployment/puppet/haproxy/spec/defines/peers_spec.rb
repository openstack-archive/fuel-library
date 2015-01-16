require 'spec_helper'

describe 'haproxy::peers' do
  let(:facts) {{ :ipaddress => '1.1.1.1' }}

  context "when no options are passed" do
    let(:title) { 'bar' }

    it { should contain_concat__fragment('bar_peers_block').with(
      'order'   => '30-peers-00-bar',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\npeers bar\n"
    ) }
  end
end
