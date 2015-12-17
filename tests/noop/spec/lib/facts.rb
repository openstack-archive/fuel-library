require 'yaml'

class Noop
  module Facts

    def override_facts
      facts = {}
      return facts unless hiera_facts_override_present?
      begin
        override_facts = YAML.load_file facts_yaml_path
        return {} unless facts.is_a? Hash
        override_facts.each do |fact, value|
          facts[fact.to_sym] = value
        end
        facts
      rescue
        return {}
      end
    end

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
          :operatingsystemmajrelease => '14',
          :lsbdistid => 'Ubuntu',
          :l3_fqdn_hostname => hostname,
          :l3_default_route => '172.16.1.1',
          :concat_basedir => '/tmp/',
          :l23_os => 'ubuntu',
          :os_package_type => 'debian',
      }.merge override_facts
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
          :operatingsystemmajrelease => '6',
          :lsbdistid => 'CentOS',
          :l3_fqdn_hostname => hostname,
          :l3_default_route => '172.16.1.1',
          :concat_basedir => '/tmp/',
          :l23_os => 'centos6',
          :os_package_type => 'rpm',
      }.merge override_facts
    end

  end
  extend Facts
end
