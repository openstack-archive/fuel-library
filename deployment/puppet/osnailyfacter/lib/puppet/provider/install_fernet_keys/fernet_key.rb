require 'fileutils'
require 'etc'
Puppet::Type.type(:install_fernet_keys).provide :fernet_key do
  desc 'install fernet keys'

  def exists?
    return false unless File.exists? stagekey
    return false unless File.exists? primkey
    authkey_present?
  end

  def create
    FileUtils.mkdir_p ferndir unless File.exists? ferndir
    FileUtils.cp @resource[:staged_key_path], stagekey
    FileUtils.cp @resource[:primary_key_path], primkey
    FileUtils.chown_R uid, gid, ferndir
    FileUtils.chmod_R 0600, ferndir
    FileUtils.chmod 0700, ferndir
  end

  def ferndir
    File.join(@resource[:keystone_dir], 'fernet-keys')

  end

  def stagekey
     "#{ferndir}/#{@resource[:staged_key_name]}"
  end

  def primkey
     "#{ferndir}/#{@resource[:primary_key_name]}"
  end

  def uid
    Etc.getpwnam(@resource[:user]).uid
  end

  def gid
    Etc.getpwnam(@resource[:user]).gid
  end
end
