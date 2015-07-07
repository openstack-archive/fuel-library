require 'beaker-rspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper

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
      on host, puppet('module','install','puppetlabs-mysql'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','puppetlabs-concat','--version','1.2.2'), { :acceptable_exit_codes => 0 }
      # pin apt module until openstack_extras use >= 2.0.0 version
      on host, puppet('module','install','puppetlabs-apt', '--version', '1.8.0'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','puppetlabs-inifile'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','puppetlabs-rsync'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','saz-memcached'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','stahnma-epel'), { :acceptable_exit_codes => 0 }

      # install puppet modules from git, use master
      shell('git clone https://git.openstack.org/openstack/puppet-openstacklib /etc/puppet/modules/openstacklib')
      shell('git clone https://git.openstack.org/openstack/puppet-openstack_extras /etc/puppet/modules/openstack_extras')
      shell('git clone https://git.openstack.org/openstack/puppet-keystone /etc/puppet/modules/keystone')

      # Install the module being tested
      puppet_module_install(:source => proj_root, :module_name => 'swift')
      # List modules installed to help with debugging
      on hosts[0], puppet('module','list'), { :acceptable_exit_codes => 0 }
    end
  end
end
