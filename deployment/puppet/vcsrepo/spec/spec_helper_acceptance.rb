require 'beaker-rspec'

unless ENV['RS_PROVISION'] == 'no' or ENV['BEAKER_provision'] == 'no'
  # This will install the latest available package on el and deb based
  # systems fail on windows and osx, and install via gem on other *nixes
  foss_opts = { :default_action => 'gem_install' }

  if default.is_pe?; then install_pe; else install_puppet( foss_opts ); end

  hosts.each do |host|
    unless host.is_pe?
      on hosts, "mkdir -p #{hosts.first['distmoduledir']}"
    end

    # We ask the host to interpolate it's distmoduledir because we don't
    # actually know it on Windows until we've let it redirect us (depending
    # on whether we're running as a 32/64 bit process on 32/64 bit Windows
    moduledir = on(host, "echo #{host['distmoduledir']}").stdout.chomp
    on host, "mkdir -p #{moduledir}"
  end
end


RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do

    # ensure test dependencies are available on all hosts
    hosts.each do |host|
      copy_module_to(host, :source => proj_root, :module_name => 'vcsrepo')
      case fact_on(host, 'osfamily')
      when 'RedHat'
        if fact_on(host, 'operatingsystemmajrelease') == '5'
          will_install_git = on(host, 'which git', :acceptable_exit_codes => [0,1]).exit_code == 1

          if will_install_git
            on host, puppet('module install stahnma-epel')
            apply_manifest_on( host, 'include epel' )
          end

        end

        install_package(host, 'git')

      when 'Debian'
        install_package(host, 'git-core')

      else
        if !check_for_package(host, 'git')
          puts "Git package is required for this module"
          exit
        end
      end
      on host, 'git config --global user.email "root@localhost"'
      on host, 'git config --global user.name "root"'
    end
  end
end
