require 'spec_helper'

describe 'haproxy::balancermember' do
  let(:title) { 'tyler' }
  let(:facts) do
    { :ipaddress => '1.1.1.1',
      :hostname  => 'dero'
    }
  end

  context 'with a single balancermember option' do
    let(:params) do
      { :name                   => 'tyler',
        :listening_service      => 'croy',
        :balancer_port          => '18140',
        :balancermember_options => 'check'
      }
    end

    it { should contain_concat__fragment('croy_balancermember_tyler').with(
      'order'   => '20',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "  server  dero 1.1.1.1:18140  check\n\n"
      ) }
  end

  context 'with multiple balancermember options' do
    let(:params) do
      { :name                   => 'tyler',
        :listening_service      => 'croy',
        :balancer_port          => '18140',
        :balancermember_options => ['check', 'close']
      }
    end

    it { should contain_concat__fragment('croy_balancermember_tyler').with(
      'order'   => '20',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "  server  dero 1.1.1.1:18140  check close\n\n"
      ) }
  end

  context 'with multiple servers' do
    let(:params) do
      { :name                   => 'tyler',
        :listening_service      => 'croy',
        :balancer_port          => '18140',
        :server_name            => ['server01', 'server02'],
        :balancer_ip            => ['192.168.56.200', '192.168.56.201'],
        :balancermember_options => ['check']
      }
    end

    it { should contain_concat__fragment('croy_balancermember_tyler').with(
      'order'   => '20',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "  server  server01 192.168.56.200:18140  check\n  server  server02 192.168.56.201:18140  check\n\n"
      ) }
  end
end
