require 'spec_helper'

describe 'haproxy::balancermember' do
  let(:pre_condition) { 'include haproxy' }
  let(:title) { 'tyler' }
  let(:facts) do
    {
      :ipaddress      => '1.1.1.1',
      :hostname       => 'dero',
      :osfamily       => 'Redhat',
      :concat_basedir => '/dne',
    }
  end

  context 'with a single balancermember option' do
    let(:params) do
      {
        :name              => 'tyler',
        :listening_service => 'croy',
        :ports             => '18140',
        :options           => 'check'
      }
    end

    it { should contain_concat__fragment('croy_balancermember_tyler').with(
      'order'   => '20-croy-01-tyler',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "  server dero 1.1.1.1:18140 check\n"
    ) }
  end

  context 'with a balancermember with ensure => absent ' do
    let(:params) do
      {
        :name              => 'tyler',
        :listening_service => 'croy',
        :ports             => '18140',
        :ensure            => 'absent'
      }
    end

    it { should contain_concat__fragment('croy_balancermember_tyler').with(
      'order'   => '20-croy-01-tyler',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'ensure'  => 'absent',
      'content' => "  server dero 1.1.1.1:18140 \n"
    ) }
  end

  context 'with multiple balancermember options' do
    let(:params) do
      {
        :name              => 'tyler',
        :listening_service => 'croy',
        :ports             => '18140',
        :options           => ['check', 'close']
      }
    end

    it { should contain_concat__fragment('croy_balancermember_tyler').with(
      'order'   => '20-croy-01-tyler',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "  server dero 1.1.1.1:18140 check close\n"
    ) }
  end

  context 'with cookie and multiple balancermember options' do
    let(:params) do
      {
        :name              => 'tyler',
        :listening_service => 'croy',
        :ports             => '18140',
        :options           => ['check', 'close'],
        :define_cookies    => true
      }
    end

    it { should contain_concat__fragment('croy_balancermember_tyler').with(
      'order'   => '20-croy-01-tyler',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "  server dero 1.1.1.1:18140 cookie dero check close\n"
    ) }
  end
  context 'with multiple servers' do
    let(:params) do
      {
        :name              => 'tyler',
        :listening_service => 'croy',
        :ports             => '18140',
        :server_names      => ['server01', 'server02'],
        :ipaddresses       => ['192.168.56.200', '192.168.56.201'],
        :options           => ['check']
      }
    end

    it { should contain_concat__fragment('croy_balancermember_tyler').with(
      'order'   => '20-croy-01-tyler',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "  server server01 192.168.56.200:18140 check\n  server server02 192.168.56.201:18140 check\n"
    ) }
  end
  context 'with multiple servers and multiple ports' do
    let(:params) do
      {
        :name              => 'tyler',
        :listening_service => 'croy',
        :ports             => ['18140','18150'],
        :server_names      => ['server01', 'server02'],
        :ipaddresses       => ['192.168.56.200', '192.168.56.201'],
        :options           => ['check']
      }
    end

    it { should contain_concat__fragment('croy_balancermember_tyler').with(
      'order'   => '20-croy-01-tyler',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "  server server01 192.168.56.200:18140 check\n  server server01 192.168.56.200:18150 check\n  server server02 192.168.56.201:18140 check\n  server server02 192.168.56.201:18150 check\n"
    ) }
  end
  context 'with multiple servers and no port' do
    let(:params) do
      {
        :name              => 'tyler',
        :listening_service => 'croy',
        :server_names      => ['server01', 'server02'],
        :ipaddresses       => ['192.168.56.200', '192.168.56.201'],
        :options           => ['check']
      }
    end

    it { should contain_concat__fragment('croy_balancermember_tyler').with(
      'order'   => '20-croy-01-tyler',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "  server server01 192.168.56.200 check\n  server server02 192.168.56.201 check\n"
    ) }
  end
end
