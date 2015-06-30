require 'beaker-rspec'

hosts.each do |host|

  install_puppet

  on host, "mkdir -p #{host['distmoduledir']}"
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    hosts.each do |host|

      # install git
      install_package host, 'git'

      # clean out any module cruft
      shell('rm -fr /etc/puppet/modules/*')

      # install library modules from the forge
      on host, puppet('module','install','puppetlabs-stdlib'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','puppetlabs-apache'), { :acceptable_exit_codes => 0 }
      # 2.0.0 make the catalog fail
      # "Unable to determine lsbdistid, is lsb-release installed?"
      # while lsb-release is installed.
      on host, puppet('module','install','puppetlabs-apt','--version', '1.8.0'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','saz/memcached'), { :acceptable_exit_codes => 0 }
      shell('git clone https://git.openstack.org/openstack/puppet-openstack_extras /etc/puppet/modules/openstack_extras')

      # Install the module being tested
      puppet_module_install(:source => proj_root, :module_name => 'horizon')
      # List modules installed to help with debugging
      on hosts[0], puppet('module','list'), { :acceptable_exit_codes => 0 }
    end
  end
end
