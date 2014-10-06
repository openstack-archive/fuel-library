require 'rubygems'
require 'yaml'

module Package
  REMOVED_PACKAGES_LIST='/var/lib/removed_packages.txt'

  def get_rpm_packages
    `rpm -qa --queryformat '%{NAME}|%{VERSION}-%{RELEASE}\n'`
  end

  def get_deb_packages
    `dpkg-query --show -f='${Package}|${Version}|${Status}\n'`
  end

  def packages_list_yaml
    if osfamily == 'Debian'
      file = 'ubuntu-packages.yaml'
    elsif osfamily == 'RedHat'
      file = 'centos-packages.yaml'
    else
      raise "Unknown osfamily: #{osfamily}"
    end

    begin
      File.read File.join(File.dirname(__FILE__), '../data', file)
    rescue
      nil
    end
  end

  def packages_by_versions
    return @pkgs if @pkgs
    content =  packages_list_yaml
    return {} unless content
    @pkgs = YAML.load content
  end

  def packages_by_versions_renew
    @pkgs = nil
    packages_by_versions
  end

  def version_transition_key
    return nil unless openstack_version and openstack_version_prev
    "#{openstack_version_prev}->#{openstack_version}"
  end

  def patching_packages_to_remove
    return [] unless packages_by_versions.is_a? Hash
    return [] unless packages_by_versions.key? version_transition_key
    packages_by_versions[version_transition_key].fetch 'remove', []
  end

  def patching_packages_to_install
    return [] unless packages_by_versions.is_a? Hash
    return [] unless packages_by_versions.key? version_transition_key
    packages_by_versions[version_transition_key].fetch 'install', []
  end

  def parse_rpm_packages
    packages = {}
    get_rpm_packages.split("\n").each do |package|
      fields = package.split('|')
      name = fields[0]
      version = fields[1]
      if name
        packages.store name, version
      end
    end
    packages
  end

  def parse_deb_packages
    packages = {}
    get_deb_packages.split("\n").each do |package|
      fields = package.split('|')
      name = fields[0]
      version = fields[1]
      if fields[2] == 'install ok installed'
        installed = true
      else
        installed = false
      end
      if installed and name
        packages.store name, version
      end
    end
    packages
  end

  def installed_packages_with_renew
    @installed_packages = nil
    installed_packages
  end

  def installed_packages
    return @installed_packages if @installed_packages
    if osfamily == 'RedHat'
      @installed_packages = parse_rpm_packages
    elsif osfamily == 'Debian'
      @installed_packages = parse_deb_packages
    else
      raise "Unknown osfamily: #{osfamily}"
    end
  end

  def is_installed?(package)
    installed_packages.key? package
  end

  def filter_installed(packages)
    packages.select { |p| is_installed? p }
  end

  def remove(packages)
    packages = Array packages
    return true unless packages.any?
    if osfamily == 'RedHat'
      stdout, return_code = run "yum erase -y #{packages.join ' '}"
      parse_rpm_remove stdout
    elsif osfamily == 'Debian'
      stdout, return_code = run "aptitude remove -y #{packages.join ' '}"
      parse_deb_remove stdout
      dpkg_configure_all
    else
      raise "Unknown osfamily: #{osfamily}"
    end
    save_removed_packages_list
    removed_packages
  end

  def dpkg_configure_all
    run 'dpkg --configure -a'
  end

  def parse_deb_remove(stdout)
    if not stdout or stdout == ''
      @removed_packages = []
      return @removed_packages
    end
    @removed_packages = []
    stdout.split("\n").inject({}) do |removed, line|
      if line =~ /^Removing\s+(\S+)/
        @removed_packages << $1 if $1
      end
    end
    @removed_packages.sort!
  end

  def parse_rpm_remove(stdout)
    if not stdout or stdout == ''
      @removed_packages = []
      return @removed_packages
    end
    @removed_packages = []
    in_block = false
    stdout.split("\n").inject({}) do |removed, line|
      if line =~ /^Removing:/ and not in_block
        in_block = true
        next
      end

      if line =~/^Transaction Summary/ and in_block
        in_block = false
        next
      end

      if in_block
        if line =~ /^\s*(\S+)/
          @removed_packages << $1 if $1
        end
      end
    end
    @removed_packages.sort!
  end

  def save_removed_packages_list
    return unless removed_packages.any?
    begin
      File.open(REMOVED_PACKAGES_LIST, 'w') do |file|
        file.write removed_packages.join "\n"
      end
    rescue
      return false
    end
  end

  def load_removed_pakages_list
    @removed_packages = []
    return @removed_packages unless File.exists? REMOVED_PACKAGES_LIST
    begin
      @removed_packages = File.read(REMOVED_PACKAGES_LIST).chomp.split("\n")
    rescue
      @removed_packages = []
    end
    @removed_packages
  end

  def removed_packages
    return @removed_packages if @removed_packages and @removed_packages.any?
    load_removed_pakages_list
  end

  def install(packages)
    packages = Array packages
    return true unless packages.any?
    if osfamily == 'RedHat'
      run "yum install -y #{packages.join ' '}"
    elsif osfamily == 'Debian'
      run "aptitude install -y #{packages.join ' '}"
      dpkg_configure_all
    else
      raise "Unknown osfamily: #{osfamily}"
    end
  end

  def install_removed_packages(key_packages = [])
    if removed_packages.length == 0 and key_packages.length > 0
      install key_packages
    elsif key_packages.length == 0 and removed_packages.length > 0
      install removed_packages
    elsif key_packages.length > 0 and removed_packages.length > 0
      to_install = key_packages.select do |kp|
        removed_packages.include? kp
      end
      install to_install
    end
  end

  def uninstall_packages(packages)
    remove filter_installed(packages)
  end

  def reset_repos
    if osfamily == 'RedHat'
      run 'yum clean all'
      run 'yum makecache'
    elsif osfamily == 'Debian'
      run 'apt-get clean'
      run 'apt-get update'
    else
      raise "Unknown osfamily: #{osfamily}"
    end
  end

  def reinstall_with_remove(packages)
    uninstall_packages packages
    install_removed_packages
  end

end
