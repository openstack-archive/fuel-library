require 'puppet/util/feature'

# Add the simple features, all in one file.

# Order is important as some features depend on others

# We have a syslog implementation
Puppet.features.add(:syslog, :libs => ["syslog"])

# We can use POSIX user functions
Puppet.features.add(:posix) do
  require 'etc'
  !Etc.getpwuid(0).nil? && Puppet.features.syslog?
end

# We can use Microsoft Windows functions
Puppet.features.add(:microsoft_windows) do
  begin
    # ruby
    require 'Win32API'          # case matters in this require!
    require 'win32ole'
    require 'win32/registry'
    # gems
    require 'sys/admin'
    require 'win32/process'
    require 'win32/dir'
    require 'win32/service'
    require 'win32/api'
    require 'win32/taskscheduler'
    true
  rescue LoadError => err
    warn "Cannot run on Microsoft Windows without the sys-admin, win32-process, win32-dir, win32-service and win32-taskscheduler gems: #{err}" unless Puppet.features.posix?
  end
end

raise Puppet::Error,"Cannot determine basic system flavour" unless Puppet.features.posix? or Puppet.features.microsoft_windows?

# We've got LDAP available.
Puppet.features.add(:ldap, :libs => ["ldap"])

# We have the Rdoc::Usage library.
Puppet.features.add(:usage, :libs => %w{rdoc/ri/ri_paths rdoc/usage})

# We have libshadow, useful for managing passwords.
Puppet.features.add(:libshadow, :libs => ["shadow"])

# We're running as root.
Puppet.features.add(:root) { require 'puppet/util/suidmanager'; Puppet::Util::SUIDManager.root? }

# We have lcs diff
Puppet.features.add :diff, :libs => %w{diff/lcs diff/lcs/hunk}

# We have augeas
Puppet.features.add(:augeas, :libs => ["augeas"])

# We have RRD available
Puppet.features.add(:rrd_legacy, :libs => ["RRDtool"])
Puppet.features.add(:rrd, :libs => ["RRD"])

# We have OpenSSL
Puppet.features.add(:openssl, :libs => ["openssl"])

# We have CouchDB
Puppet.features.add(:couchdb, :libs => ["couchrest"])

# We have sqlite
Puppet.features.add(:sqlite, :libs => ["sqlite3"])

# We have Hiera
Puppet.features.add(:hiera, :libs => ["hiera"])

Puppet.features.add(:minitar, :libs => ["archive/tar/minitar"])

# We can manage symlinks
Puppet.features.add(:manages_symlinks) do
  if ! Puppet::Util::Platform.windows?
    true
  else
    begin
      require 'Win32API'
      Win32API.new('kernel32', 'CreateSymbolicLink', 'SSL', 'B')
      true
    rescue LoadError => err
      Puppet.debug("CreateSymbolicLink is not available")
      false
    end
  end
end
