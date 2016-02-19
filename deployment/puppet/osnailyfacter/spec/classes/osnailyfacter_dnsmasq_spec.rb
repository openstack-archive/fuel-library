require 'spec_helper'

describe 'osnailyfacter::dnsmasq' do
  let :facts do
    {
      :osfamily               => 'Debian',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
      :concat_basedir         => '/var/lib/puppet/concat',
      :domain                 => 'example.com'
    }
  end


  context 'with valid params' do
    let :params do
      {
        :external_dns => ['8.8.8.8', '4.4.4.4'],
        :master_ip => '10.20.0.2',
        :management_vrouter_vip => '10.20.0.1'
      }
    end

    it 'should ensure package' do
      should contain_package('dnsmasq-base')
    end

    it 'should configure dnsmasq' do
      should contain_file('/etc/dnsmasq.d').with_ensure('directory')
      should contain_file('/etc/resolv.dnsmasq.conf').with(
        :ensure => 'present',
        :content => "nameserver 8.8.8.8\nnameserver 4.4.4.4\n"
      )
      should contain_file('/etc/dnsmasq.d/dns.conf').with(
        :ensure => 'present'
      ).with(
        :content => /domain=example.com/
      ).with(
        :content => /listen-address=10.20.0.1/
      ).with(
        :content => /server=\/example.com\/10.20.0.2/
      )
    end
  end

  context 'with invalid params' do
    let :params do
      {
        :external_dns => '8.8.8.8',
        :master_ip => '10.20.0.2',
        :management_vrouter_vip => '10.20.0.1'
      }
    end

    it 'should error with string passed to external dns' do
      expect { catalogue }.to raise_error(Puppet::Error, /is not an Array/)
    end

  end
end

