class Noop
  module Facts

    def ubuntu_facts
      {
          :fqdn => fqdn,
          :hostname => hostname,
          :physicalprocessorcount => '4',
          :processorcount => '4',
          :memorysize_mb => '32138.66',
          :memorysize => '31.39 GB',
          :kernel => 'Linux',
          :osfamily => 'Debian',
          :operatingsystem => 'Ubuntu',
          :operatingsystemrelease => '14.04',
          :lsbdistid => 'Ubuntu',
          :l3_fqdn_hostname => hostname,
          :l3_default_route => '172.16.1.1',
          :concat_basedir => '/tmp/',
          :l23_os => 'ubuntu',
          :os_service_default => '<SERVICE DEFAULT>',
      }
    end

    def centos_facts
      {
          :fqdn => fqdn,
          :hostname => hostname,
          :physicalprocessorcount => '4',
          :processorcount => '4',
          :memorysize_mb => '32138.66',
          :memorysize => '31.39 GB',
          :kernel => 'Linux',
          :osfamily => 'RedHat',
          :operatingsystem => 'CentOS',
          :operatingsystemrelease => '6.5',
          :lsbdistid => 'CentOS',
          :l3_fqdn_hostname => hostname,
          :l3_default_route => '172.16.1.1',
          :concat_basedir => '/tmp/',
          :l23_os => 'centos6',
          :os_service_default => '<SERVICE DEFAULT>',
      }
    end

  end
  extend Facts
end
