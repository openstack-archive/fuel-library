require 'spec_helper'

describe 'haproxy::frontend' do
  let(:title) { 'tyler' }
  let(:facts) {{ :ipaddress => '1.1.1.1' }}
  context "when only one port is provided" do
    let(:params) do
      {
        :name  => 'croy',
        :ports => '18140'
      }
    end

    it { should contain_concat__fragment('croy_frontend_block').with(
      'order'   => '15-croy-00',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\nfrontend croy\n  bind 1.1.1.1:18140 \n  option  tcplog\n"
    ) }
  end
  # C9948 C9947
  context "when an array of ports is provided" do
    let(:params) do
      {
        :name      => 'apache',
        :ipaddress => '23.23.23.23',
        :ports     => [
          '80',
          '443'
        ]
      }
    end

    it { should contain_concat__fragment('apache_frontend_block').with(
      'order'   => '15-apache-00',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\nfrontend apache\n  bind 23.23.23.23:80 \n  bind 23.23.23.23:443 \n  option  tcplog\n"
    ) }
  end
  # C9948
  context "when a comma-separated list of ports is provided" do
    let(:params) do
      {
        :name      => 'apache',
        :ipaddress => '23.23.23.23',
        :ports     => '80,443'
      }
    end

    it { should contain_concat__fragment('apache_frontend_block').with(
      'order'   => '15-apache-00',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\nfrontend apache\n  bind 23.23.23.23:80 \n  bind 23.23.23.23:443 \n  option  tcplog\n"
    ) }
  end
  # C9971
  context "when empty list of ports is provided" do
    let(:params) do
      {
        :name      => 'apache',
        :ipaddress => '23.23.23.23',
        :ports     => [],
      }
    end

    it { should contain_concat__fragment('apache_frontend_block').with(
      'order'   => '15-apache-00',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\nfrontend apache\n  option  tcplog\n"
    ) }
  end
  # C9972
  context "when a port is provided greater than 65535" do
    let(:params) do
      {
        :name      => 'apache',
        :ipaddress => '23.23.23.23',
        :ports     => '80443'
      }
    end

    it 'should raise error' do
      expect { subject }.to raise_error Puppet::Error, /outside of range/
    end
  end
  # C9946
  context "when multiple ports are provided greater than 65535" do
    let(:params) do
      {
        :name      => 'apache',
        :ipaddress => '23.23.23.23',
        :ports     => ['80443','80444']
      }
    end

    it 'should raise error' do
      expect { subject }.to raise_error Puppet::Error, /outside of range/
    end
  end
  # C9973
  context "when an invalid ipv4 address is passed" do
    let(:params) do
      {
        :name      => 'apache',
        :ipaddress => '2323.23.23',
        :ports     => '80'
      }
    end

    it 'should raise error' do
      expect { subject }.to raise_error Puppet::Error, /Invalid IP address/
    end
  end
  # C9949
  context "when a ports parameter and a bind parameter are passed" do
    let(:params) do
      {
        :name  => 'apache',
        :bind  => {'192.168.0.1:80' => ['ssl']},
        :ports => '80'
      }
    end

    it 'should raise error' do
      expect { subject }.to raise_error Puppet::Error, /mutually exclusive/
    end
  end
  context "when multiple IPs are provided" do
    let(:params) do
      {
        :name      => 'apache',
        :ipaddress => ['23.23.23.23','23.23.23.24'],
        :ports     => '80'
      }
    end

    it { should contain_concat__fragment('apache_frontend_block').with(
      'order'   => '15-apache-00',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\nfrontend apache\n  bind 23.23.23.23:80 \n  bind 23.23.23.24:80 \n  option  tcplog\n"
    ) }
  end
  context "when bind options are provided" do
    let(:params) do
      {
        :name         => 'apache',
        :ports        => ['80','8080'],
        :bind_options => [ 'the options', 'go here' ]
      }
    end

    it { should contain_concat__fragment('apache_frontend_block').with(
      'order'   => '15-apache-00',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\nfrontend apache\n  bind 1.1.1.1:80 the options go here\n  bind 1.1.1.1:8080 the options go here\n  option  tcplog\n"
    ) }
  end
  context "when a comma-separated list of ports is provided" do
    let(:params) do
      {
        :name      => 'apache',
        :ipaddress => '23.23.23.23',
        :ports     => '80,443'
      }
    end

    it { should contain_concat__fragment('apache_frontend_block').with(
      'order'   => '15-apache-00',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\nfrontend apache\n  bind 23.23.23.23:80 \n  bind 23.23.23.23:443 \n  option  tcplog\n"
    ) }
  end

  # C9950 C9951 C9952 WONTFIX
end
