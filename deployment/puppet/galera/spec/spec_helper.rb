require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'

module Facts
  def self.fqdn
    'server.example.com'
  end

  def self.hostname
    self.fqdn.split('.').first
  end

  def self.ipaddress
    '10.0.0.1'
  end

  def self.ubuntu_facts
    {
        :fqdn                 => fqdn,
        :hostname             => hostname,
        :processorcount       => '4',
        :memorysize_mb        => '32138.66',
        :memorysize           => '31.39 GB',
        :kernel               => 'Linux',
        :osfamily             => 'Debian',
        :operatingsystem      => 'Ubuntu',
        :operatingsystemrelease => '14.04',
        :lsbdistid            => 'Ubuntu',
        :concat_basedir       => '/tmp/',
        :ipaddress_eth0       => ipaddress
    }
  end

  def self.centos_facts
    {
        :fqdn                 => fqdn,
        :hostname             => hostname,
        :processorcount       => '4',
        :memorysize_mb        => '32138.66',
        :memorysize           => '31.39 GB',
        :kernel               => 'Linux',
        :osfamily             => 'RedHat',
        :operatingsystem      => 'CentOS',
        :operatingsystemrelease => '6.5',
        :lsbdistid            => 'CentOS',
        :concat_basedir       => '/tmp/',
        :ipaddress_eth0       => ipaddress
    }
  end
end

# Generage coverage report at the end of a run
at_exit { RSpec::Puppet::Coverage.report! }

# vim: set ts=2 sw=2 et :
