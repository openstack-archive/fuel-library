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
      on host, puppet('module','install','dprince/qpid'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','duritong/sysctl'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','puppetlabs-inifile'), { :acceptable_exit_codes => 0 }
      on host, puppet('module','install','stahnma-epel'), { :acceptable_exit_codes => 0 }
      # pin apt module until openstack_extras use >= 2.0.0 version
      on host, puppet('module','install','puppetlabs-apt','--version','1.8.0'), { :acceptable_exit_codes => 0 }

      # install puppet modules from git, use master
      shell('git clone https://git.openstack.org/openstack/puppet-openstacklib /etc/puppet/modules/openstacklib')
      shell('git clone https://git.openstack.org/openstack/puppet-openstack_extras /etc/puppet/modules/openstack_extras')
      shell('git clone https://git.openstack.org/openstack/puppet-keystone /etc/puppet/modules/keystone')
      shell('git clone https://git.openstack.org/openstack/puppet-cinder /etc/puppet/modules/cinder')
      shell('git clone https://git.openstack.org/openstack/puppet-glance /etc/puppet/modules/glance')
      # TODO(EmilienM) Cloning RabbitMQ module for now because we wait for a release including
      # https://github.com/enovance/puppetlabs-rabbitmq/commit/0227f762070ffbbea3c28d6a60174de98fa4cc1c
      shell('git clone https://github.com/puppetlabs/puppetlabs-rabbitmq/ /etc/puppet/modules/rabbitmq')

      # Install the module being tested
      puppet_module_install(:source => proj_root, :module_name => 'nova')
      # List modules installed to help with debugging
      on hosts[0], puppet('module','list'), { :acceptable_exit_codes => 0 }
    end
  end
end
