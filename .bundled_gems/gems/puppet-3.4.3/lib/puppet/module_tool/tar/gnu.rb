class Puppet::ModuleTool::Tar::Gnu
  def initialize(command = "tar")
    @command = command
  end

  def unpack(sourcefile, destdir, owner)
    Puppet::Util::Execution.execute("#{@command} xzf #{sourcefile} --no-same-owner -C #{destdir}")
    Puppet::Util::Execution.execute("find #{destdir} -type d -exec chmod 755 {} +")
    Puppet::Util::Execution.execute("find #{destdir} -type f -exec chmod a-wst {} +")
    Puppet::Util::Execution.execute("chown -R #{owner} #{destdir}")
  end

  def pack(sourcedir, destfile)
    Puppet::Util::Execution.execute("tar cf - #{sourcedir} | gzip -c > #{destfile}")
  end
end
