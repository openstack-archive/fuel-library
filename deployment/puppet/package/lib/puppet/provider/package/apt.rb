require 'yaml'

Puppet::Type.type(:package).provide :apt, :parent => :dpkg, :source => :dpkg do
  # Provide sorting functionality
  include Puppet::Util::Package

  desc "Package management via `apt-get`."

  has_feature :versionable

  commands :aptget => "/usr/bin/apt-get"
  commands :aptcache => "/usr/bin/apt-cache"
  commands :preseed => "/usr/bin/debconf-set-selections"
  commands :dpkgquery => '/usr/bin/dpkg-query'

  defaultfor :operatingsystem => [:debian, :ubuntu]

  ENV['DEBIAN_FRONTEND'] = "noninteractive"

  # disable common apt helpers to allow non-interactive package installs
  ENV['APT_LISTBUGS_FRONTEND'] = "none"
  ENV['APT_LISTCHANGES_FRONTEND'] = "none"

  # A derivative of DPKG; this is how most people actually manage
  # Debian boxes, and the only thing that differs is that it can
  # install packages from remote sites.

  def checkforcdrom
    have_cdrom = begin
                   !!(File.read("/etc/apt/sources.list") =~ /^[^#]*cdrom:/)
                 rescue
                   # This is basically pathological...
                   false
                 end

    if have_cdrom and @resource[:allowcdrom] != :true
      raise Puppet::Error,
        "/etc/apt/sources.list contains a cdrom source; not installing.  Use 'allowcdrom' to override this failure."
    end
  end

  # @param pkg <Hash,TrueClass,FalseClass,Symbol,String>
  # @param action <Symbol>
  def install_cmd(pkg)
    cmd = %w{-q -y}

    config = @resource[:configfiles]
    if config == :keep
      cmd << "-o" << 'DPkg::Options::=--force-confold'
    else
      cmd << "-o" << 'DPkg::Options::=--force-confnew'
    end

    cmd << '--force-yes'
    cmd << :install

    if pkg.is_a? Hash
      # make install string from package hash
      cmd += pkg.map do |p|
        if p[1] == :absent
          "#{p[0]}-"
        else
          "#{p[0]}=#{p[1]}"
        end
      end
    elsif pkg.is_a? String
      # install a specific version
      cmd << "#{@resource[:name]}=#{pkg}"
    else
      # install any version
      cmd << @resource[:name]
    end

    cmd
  end

  # Install a package using 'apt-get'.  This function needs to support
  # installing a specific version.
  def install
    self.run_preseed if @resource[:responsefile]
    should = @resource[:ensure]
    @file_dir = '/var/lib/puppet/rollback'

    checkforcdrom

    name = @resource[:name]
    from = @property_hash[:ensure]
    to = @resource[:ensure]
    to = latest if to == :latest

    Puppet.debug "Installing package #{name} from #{from} to #{to}"

    rollback_file = File.join @file_dir, "#{name}_#{to}_#{from}.yaml"
    diff = read_diff rollback_file

    if diff.is_a?(Hash) && diff.key?('installed') && diff.key?('removed')
      # rollback
      Puppet.debug "Found rollback file at #{rollback_file}"
      installed = diff['installed']
      removed = diff['removed']

      # calculate package sets
      to_update = package_updates removed, installed
      to_install = package_diff removed, installed
      to_remove = package_diff installed, removed, true

      Puppet.debug "Install: #{to_install.map {|p| "#{p[0]}=#{p[1]}" }. join ' '}" if to_install.any?
      Puppet.debug "Remove: #{to_remove.map {|p| "#{p[0]}=#{p[1]}" }. join ' '}" if to_remove.any?
      Puppet.debug "Update: #{to_update.map {|p| "#{p[0]}=#{p[1]}" }. join ' '}" if to_update.any?

      # combine package lists to a single list
      to_remove.each_pair {|k,v| to_remove.store k, :absent}
      all_packages = to_install.merge(to_update).merge to_remove

      if all_packages.any?
        Puppet.debug "All: #{all_packages.map {|p| "#{p[0]}=#{p[1]}" }. join ' '}" if all_packages.any?
        cmd = install_cmd all_packages
        aptget *cmd
      end
    elsif from.is_a?(String) && to.is_a?(String)
      # update
      cmd = install_cmd should
      before,after = aptget_with_changes cmd
      diff = make_package_diff before, after
      file_path = File.join @file_dir, "#{name}_#{from}_#{to}.yaml"
      Puppet.notice "Saving diff file to #{file_path}"
      save_diff file_path, diff
    else
      # just install the package
      cmd = install_cmd should
      aptget *cmd
    end
  end

  def aptget_with_changes(cmd)
    before = pkg_list
    aptget *cmd
    after = pkg_list
    [ before, after ]
  end

  def make_package_diff(before, after)
    installed = package_diff after, before
    removed = package_diff before, after
    { 'installed' => installed, 'removed'   => removed }
  end

  # saves diff hash into a file
  # @param file_path <String>
  # @param diff <Hash[String]>
  def save_diff(file_path, diff)
    require 'yaml'
    Dir.mkdir @file_dir unless File.directory? @file_dir
    File.open(file_path, 'w') { |file| file.write YAML.dump(diff) + "\n" }
  end

  # reads diff hash from a file
  # @param file_path <String>
  # @returns <Hash[String]>
  def read_diff(file_path)
    return unless File.readable? file_path
    diff = YAML.load_file file_path
    return unless diff.is_a? Hash
    diff
  end

  # Substract packages in hash b from packages in hash a
  # in noval is true only package name matters and version is ignored
  # @param a <Hash[String]>
  # @param b <Hash[String]>
  # @param ignore_versions <TrueClass,FalseClass>
  def package_diff(a, b, ignore_versions = false)
    result = a.dup
    b.each_pair do |k, v|
      if a.key? k
        if a[k] == v or ignore_versions
          result.delete k
        end
      end
    end
    result
  end

  # find package names in both a and b hashes
  # values are taken from a
  # @param a <Hash[String]>
  # @param b <Hash[String]>
  def package_updates(a, b)
    common_keys = a.keys & b.keys
    common_keys.inject({}) { |result, p| result.merge({p => a[p]}) }
  end

  def pkg_list
    packages = {}
    raw_pkgs = dpkgquery [ '--show', '-f=${Package}|${Version}|${Status}\n' ]
    raw_pkgs.split("\n").each do |l|
      line = l.split('|')
      next unless line[2] == 'install ok installed'
      name = line[0]
      version = line[1]
      next if !name || !version
      packages.store name, version
    end
    packages
  end

  # What's the latest package version available?
  def latest
    output = aptcache :policy,  @resource[:name]

    if output =~ /Candidate:\s+(\S+)\s/
      return $1
    else
      self.err "Could not find latest version"
      return nil
    end
  end

  #
  # preseeds answers to dpkg-set-selection from the "responsefile"
  #
  def run_preseed
    if response = @resource[:responsefile] and Puppet::FileSystem::File.exist?(response)
      self.info("Preseeding #{response} to debconf-set-selections")

      preseed response
    else
      self.info "No responsefile specified or non existant, not preseeding anything"
    end
  end

  def uninstall
    self.run_preseed if @resource[:responsefile]
    aptget "-y", "-q", :remove, @resource[:name]
  end

  def purge
    self.run_preseed if @resource[:responsefile]
    aptget '-y', '-q', :remove, '--purge', @resource[:name]
    # workaround a "bug" in apt, that already removed packages are not purged
    super
  end
end
