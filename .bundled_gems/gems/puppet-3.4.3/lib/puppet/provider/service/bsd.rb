# Manage FreeBSD services.
Puppet::Type.type(:service).provide :bsd, :parent => :init do
  desc <<-EOT
    FreeBSD's (and probably NetBSD's?) form of `init`-style service management.

    Uses `rc.conf.d` for service enabling and disabling.

  EOT

  confine :operatingsystem => [:freebsd, :netbsd, :openbsd, :dragonfly]

  def rcconf_dir
    '/etc/rc.conf.d'
  end

  def self.defpath
    superclass.defpath
  end

  # remove service file from rc.conf.d to disable it
  def disable
    rcfile = File.join(rcconf_dir, @model[:name])
    File.delete(rcfile) if Puppet::FileSystem::File.exist?(rcfile)
  end

  # if the service file exists in rc.conf.d then it's already enabled
  def enabled?
    rcfile = File.join(rcconf_dir, @model[:name])
    return :true if Puppet::FileSystem::File.exist?(rcfile)

    :false
  end

  # enable service by creating a service file under rc.conf.d with the
  # proper contents
  def enable
    Dir.mkdir(rcconf_dir) if not Puppet::FileSystem::File.exist?(rcconf_dir)
    rcfile = File.join(rcconf_dir, @model[:name])
    open(rcfile, 'w') { |f| f << "%s_enable=\"YES\"\n" % @model[:name] }
  end

  # Override stop/start commands to use one<cmd>'s and the avoid race condition
  # where provider trys to stop/start the service before it is enabled
  def startcmd
    [self.initscript, :onestart]
  end

  def stopcmd
    [self.initscript, :onestop]
  end
end
