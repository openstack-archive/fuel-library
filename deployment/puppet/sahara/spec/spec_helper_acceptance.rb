require 'beaker-rspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  modname = JSON.parse(open('metadata.json').read)['name'].split('-')[1]

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    hosts.each do |host|

      # install git
      install_package host, 'git'

      zuul_ref = ENV['ZUUL_REF']
      zuul_branch = ENV['ZUUL_BRANCH']
      zuul_url = ENV['ZUUL_URL']

      repo = 'openstack/puppet-openstack-integration'

      # Start out with clean moduledir, don't trust r10k to purge it
      on host, "rm -rf /etc/puppet/modules/*"
      # Install dependent modules via git or zuul
      r = on host, "test -e /usr/zuul-env/bin/zuul-cloner", { :acceptable_exit_codes => [0,1] }
      if r.exit_code == 0
        zuul_clone_cmd = '/usr/zuul-env/bin/zuul-cloner '
        zuul_clone_cmd += '--cache-dir /opt/git '
        zuul_clone_cmd += "--zuul-ref #{zuul_ref} "
        zuul_clone_cmd += "--zuul-branch #{zuul_branch} "
        zuul_clone_cmd += "--zuul-url #{zuul_url} "
        zuul_clone_cmd += "git://git.openstack.org #{repo}"
        on host, zuul_clone_cmd
      else
        on host, "git clone -b stable/kilo https://git.openstack.org/#{repo} #{repo}"
      end

      on host, "ZUUL_REF=#{zuul_ref} ZUUL_BRANCH=#{zuul_branch} ZUUL_URL=#{zuul_url} bash #{repo}/install_modules.sh"

      # Install the module being tested
      on host, "rm -fr /etc/puppet/modules/#{modname}"
      puppet_module_install(:source => proj_root, :module_name => modname)

      on host, "rm -fr #{repo}"

      # List modules installed to help with debugging
      on host, puppet('module','list'), { :acceptable_exit_codes => 0 }
    end
  end
end
