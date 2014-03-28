require 'puppet/util/package'

Puppet::Type.type(:package).provide :yum, :parent => :rpm, :source => :rpm do
  desc "Support via `yum`.

  Using this provider's `uninstallable` feature will not remove dependent packages. To
  remove dependent packages with this provider use the `purgeable` feature, but note this
  feature is destructive and should be used with the utmost care."

  has_feature :versionable

  commands :yum => "yum", :rpm => "rpm", :python => "python"

  self::YUMHELPER = File::join(File::dirname(__FILE__), "yumhelper.py")

  attr_accessor :latest_info

  if command('rpm')
    confine :true => begin
      rpm('--version')
      rescue Puppet::ExecutionFailure
        false
      else
        true
      end
  end

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  def self.prefetch(packages)
    raise Puppet::Error, "The yum provider can only be used as root" if Process.euid != 0
    super
    return unless packages.detect { |name, package| package.should(:ensure) == :latest }

    # collect our 'latest' info
    updates = {}
    python(self::YUMHELPER).each_line do |l|
      l.chomp!
      next if l.empty?
      if l[0,4] == "_pkg"
        hash = nevra_to_hash(l[5..-1])
        [hash[:name], "#{hash[:name]}.#{hash[:arch]}"].each  do |n|
          updates[n] ||= []
          updates[n] << hash
        end
      end
    end

    # Add our 'latest' info to the providers.
    packages.each do |name, package|
      if info = updates[package[:name]]
        package.provider.latest_info = info[0]
      end
    end
  end

  def pkg_list
    raw_pkgs = rpm [ '-q', '-a', '--queryformat', '%{NAME}|%{VERSION}\n' ]
    pkgs = {}
    raw_pkgs.split("\n").each do |l|
      line = l.split '|'
      name = line[0]
      version = line[1]
      next unless name and version
      pkgs.store name, version
    end
    pkgs
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
    result = {}
    common_keys.each { |p| result.store p, a[p] }
    result
  end

  def install
    should = @resource.should(:ensure)
    self.debug "Ensuring => #{should}"
    wanted = @resource[:name]
    operation = :install

    @file_dir = '/var/lib/puppet/rollback'
    @tmp_file = '/tmp/yum.shell'
    Dir.mkdir @file_dir unless File.directory? @file_dir

    from = @property_hash[:ensure]
    to = @resource[:ensure]
    name = @resource[:name]

    Puppet.notice "Installing package #{name} from #{from} to #{to}"

    case should
    when true, false, Symbol
      # pass
      should = nil
    else
      # Add the package version
      wanted += "-#{should}"
      is = self.query
      if is && Puppet::Util::Package.versioncmp(should, is[:ensure]) < 0
        self.debug "Downgrading package #{@resource[:name]} from version #{is[:ensure]} to #{should}"
        operation = :downgrade
      end
    end

    # get rollback file if present
    rollback_file = File.join @file_dir, "#{name}=#{to}=#{from}.yaml"
    require 'yaml'
    diff = nil
    diff = YAML.load_file rollback_file if File.readable? rollback_file

    # check if we are updating
    statuses = [ :purged ,:absent, :held, :latest, :instlled ]
    update = false
    update = true unless statuses.include? from or statuses.include? to

    if update
      # update form one version to another
      # saving diff to a file
      before = pkg_list
      output = yum "-d", "0", "-e", "0", "-y", operation, wanted
      after = pkg_list
      installed = package_diff after, before
      removed = package_diff before, after
      diff = {
          'installed' => installed,
          'removed'   => removed,
      }
      file_path = File.join @file_dir, "#{name}=#{from}=#{to}.yaml"
      File.open(file_path, 'w') { |file| file.write YAML.dump(diff) + "\n" }
      Puppet.debug "Saving diff file to #{file_path}"

    elsif diff.is_a? Hash
      # rollback file found
      # reverse the update process instead of usuall install
      Puppet.debug "Found rollback file at #{rollback_file}"
      installed = diff['installed']
      removed = diff['removed']
      # calculate package sets
      to_update = package_updates removed, installed
      to_install = package_diff removed, installed
      to_remove = package_diff installed, removed, true
      Puppet.debug "Install: #{to_install.map {|p| "#{p[0]}-#{p[1]}" }. join ' '}" if to_install.any?
      Puppet.debug "Remove: #{to_remove.map {|p| "#{p[0]}-#{p[1]}" }. join ' '}" if to_remove.any?
      Puppet.debug "Update: #{to_update.map {|p| "#{p[0]}-#{p[1]}" }. join ' '}" if to_update.any?
      to_install = to_install.merge to_update

      yumshell = ''
      yumshell += "#{operation} #{to_install.map {|p| "#{p[0]}-#{p[1]}" }. join ' '}\n" if to_install.any?
      yumshell += "remove #{to_remove.map {|p| "#{p[0]}-#{p[1]}" }. join ' '}\n" if to_remove.any?
      yumshell += "run\n"

      File.open(@tmp_file, 'w') { |file| file.write yumshell }
      output = yum "-d", "0", "-e", "0", "-y", 'shell', @tmp_file
      File.delete @tmp_file
    else
      # just a simple install
      output = yum "-d", "0", "-e", "0", "-y", operation, wanted
    end

    is = self.query
    raise Puppet::Error, "Could not find package #{self.name}" unless is

    # FIXME: Should we raise an exception even if should == :latest
    # and yum updated us to a version other than @param_hash[:ensure] ?
    raise Puppet::Error, "Failed to update to version #{should}, got version #{is[:ensure]} instead" if should && should != is[:ensure]
  end

  # What's the latest package version available?
  def latest
    upd = latest_info
    unless upd.nil?
      # FIXME: there could be more than one update for a package
      # because of multiarch
      return "#{upd[:epoch]}:#{upd[:version]}-#{upd[:release]}"
    else
      # Yum didn't find updates, pretend the current
      # version is the latest
      raise Puppet::DevError, "Tried to get latest on a missing package" if properties[:ensure] == :absent
      return properties[:ensure]
    end
  end

  def update
    # Install in yum can be used for update, too
    self.install
  end

  def purge
    yum "-y", :erase, @resource[:name]
  end
end
