require 'rubygems'
require 'yaml'

module Package
  REMOVED_PACKAGES_LIST='/var/lib/removed_packages.txt'

  # get a list of rpm packages using rpm command
  # @return [String] formated package list
  def get_rpm_packages
    `rpm -qa --queryformat '%{NAME}|%{VERSION}-%{RELEASE}\n'`
  end

  # get a list of deb packages using pkg-query commabd
  # @return [String] formated package list
  def get_deb_packages
    `dpkg-query --show -f='${Package}|${Version}|${Status}\n'`
  end

  # parse rpm package list and return hash of names and versions
  # @return [Hash<String => String>] package names and versions
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

  # parse deb package list and return hash of names and versions
  # @return [Hash<String => String>] package names and versions
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

  # same as installed_packages but
  # resets saved list
  # @return [Hash<String => String>]  package names and versions
  def installed_packages_with_renew
    @installed_packages = nil
    installed_packages
  end

  # get, save and return a list of installed packages
  # for both rpm and deb
  # @return [Hash<String => String>]  package names and versions
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

  # check if the package is installed
  # @param package [String] package name
  # @return [TrueClass,FalseClass] is package installed?
  def is_installed?(package)
    installed_packages.key? package
  end

  # take a list of packages names and filter only
  # those that are installed
  # @param packages [Array<String>] list of package names
  # @return [Array<String>] only installed packages from the list
  def filter_installed(packages)
    packages.select { |p| is_installed? p }
  end

  # remove one or several packages
  # and return a list of packages that were
  # actually removed
  # @param packages [String, Array<String>] package names to remove
  # @return [Array<String>] packages the were removed
  def remove(packages)
    packages = Array packages
    return true unless packages.any?
    if osfamily == 'RedHat'
      stdout, return_code = run "yum erase -y #{packages.join ' '}"
      parse_rpm_remove stdout
    elsif osfamily == 'Debian'
      stdout, return_code = run "aptitude remove -y #{packages.join ' '}"
      parse_deb_remove stdout
    else
      raise "Unknown osfamily: #{osfamily}"
    end
    save_removed_packages_list
    removed_packages
  end

  # parse the output of aptitude to get a list
  # of removed packages
  # @param stdout [String] output of aptitude
  # @return [Array<String>] removed packages
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

  # parse the output of yum to get a list
  # of removed packages
  # @param stdout [String] output of yum
  # @return [Array<String>] removed packages
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

  # save removed package list to a file
  # @return [TrueClass,FalseClass]
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

  # load removed package list from a file
  # @return [Array<String>] removed packages
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

  # get removed packages list of load it from file
  # if current list is absent or missing
  # @return [Array<String>] removed packages
  def removed_packages
    return @removed_packages if @removed_packages and @removed_packages.any?
    load_removed_pakages_list
  end

  # install a package or several packages
  # @param packages [String, Array<String>] packages to install
  def install(packages)
    packages = Array packages
    return true unless packages.any?
    if osfamily == 'RedHat'
      run "yum install -y #{packages.join ' '}"
    elsif osfamily == 'Debian'
      run "aptitude install -y #{packages.join ' '}"
    else
      raise "Unknown osfamily: #{osfamily}"
    end
  end

  # install impotant packages that were removed
  # if not packages were removed - install all impotant packages
  # if there are no impotant packages - install all removed packages
  # if there are both impotant and removed - install those impotant packages that were removed
  # this function can be used to reinstall a list of packages only if they were previously installed
  # @param key_packages [Array<String>]
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

  # uninstall several packages only if they are installed
  # @param packages [Array<String>] package to remove
  # @return [Array<String>] packages that were actually removed
  def uninstall_packages(packages)
    remove filter_installed(packages)
  end

  # clean an resync remo matadata
  # should be used after repo url was changed
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

  # uninstall packages and then install them again
  # usefull to update broken packages
  # @param packages [Array<String>]
  def reinstall_with_remove(packages)
    uninstall_packages packages
    install_removed_packages
  end

end
