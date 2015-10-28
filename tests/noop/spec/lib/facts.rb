module Noop::Facts
  def facts=(facts)
    @facts = facts
  end

  def facts
    @facts
  end

  def ubuntu_facts
    self.facts = {
        :fqdn                   => fqdn,
        :hostname               => hostname,
        :physicalprocessorcount => '4',
        :processorcount         => '4',
        :memorysize_mb          => '32138.66',
        :memorysize             => '31.39 GB',
        :kernel                 => 'Linux',
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '14.04',
        :lsbdistid              => 'Ubuntu',
        :l3_fqdn_hostname       => hostname,
        :l3_default_route       => '172.16.1.1',
        :concat_basedir         => '/tmp/',
        :l23_os                 => 'ubuntu',
    }
  end

  def centos_facts
    self.facts = {
        :fqdn                   => fqdn,
        :hostname               => hostname,
        :physicalprocessorcount => '4',
        :processorcount         => '4',
        :memorysize_mb          => '32138.66',
        :memorysize             => '31.39 GB',
        :kernel                 => 'Linux',
        :osfamily               => 'RedHat',
        :operatingsystem        => 'CentOS',
        :operatingsystemrelease => '6.5',
        :lsbdistid              => 'CentOS',
        :l3_fqdn_hostname       => hostname,
        :l3_default_route       => '172.16.1.1',
        :concat_basedir         => '/tmp/',
        :l23_os                 => 'centos6',
    }
  end
end
