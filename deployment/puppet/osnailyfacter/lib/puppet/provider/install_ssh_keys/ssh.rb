require 'fileutils'
require 'etc'
Puppet::Type.type(:install_ssh_keys).provide :ssh do
  desc 'install ssh keys'

  def exists?
    return false unless File.exists? pubkey
    return false unless File.exists? privkey
    authkey_present?
  end

  def create
    FileUtils.mkdir_p sshdir unless File.exists? sshdir
    FileUtils.cp @resource[:private_key_path], pubkey
    FileUtils.cp @resource[:public_key_path], privkey
    FileUtils.chown_R uid, gid, sshdir
    FileUtils.chmod_R 0600, sshdir
    FileUtils.chmod 0700, sshdir
    File.open(authfile, 'a') { |file| file.write sshkey } unless authkey_present?
  end

  def destroy
    FileUtils.rm pubkey if File.exists? pubkey
    FileUtils.rm privkey if File.exists? privkey
    authkey = File.read(authfile).gsub(sshkey, '')
    File.open(authfile, 'w') { |file| file.puts authkey } if File.exists? authfile
  end

  def authkey_present?
    return false unless File.exist? authfile
    File.read(authfile).grep(sshkey).any?
  end

  def sshdir
    File.join(File.expand_path("~#{@resource[:user]}"), '.ssh')
  end

  def sshkey
    File.read @resource[:public_key_path]
  end

  def pubkey
    "#{sshdir}/#{@resource[:private_key_name]}"
  end

  def privkey
    "#{sshdir}/#{@resource[:public_key_name]}"
  end

  def authfile
    "#{sshdir}/#{@resource[:authorized_keys]}"
  end

  def uid
    Etc.getpwnam(@resource[:user]).uid
  end

  def gid
    Etc.getpwnam(@resource[:user]).gid
  end
end
