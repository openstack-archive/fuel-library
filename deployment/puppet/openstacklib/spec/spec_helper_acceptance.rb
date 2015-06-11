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
      on host, puppet('module','install','puppetlabs-mysql'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','puppetlabs-apache'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','puppetlabs-postgresql'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','stahnma-epel'), { :acceptable_exit_codes => 0 }
      # until https://github.com/tamaskozak/puppetlabs-rabbitmq/commit/8bbfe320035fae2ae900211501008d63dc3c171c is part of a release
      shell('git clone https://github.com/puppetlabs/puppetlabs-rabbitmq /etc/puppet/modules/rabbitmq')
      shell('git clone https://git.openstack.org/openstack/puppet-openstack_extras /etc/puppet/modules/openstack_extras')
      # Install the module being tested
      puppet_module_install(:source => proj_root, :module_name => 'openstacklib')
      # List modules installed to help with debugging
      on hosts[0], puppet('module','list'), { :acceptable_exit_codes => 0 }
    end
  end
end
