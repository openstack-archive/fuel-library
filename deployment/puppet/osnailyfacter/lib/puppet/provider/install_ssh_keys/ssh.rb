require 'fileutils'
require 'etc'
Puppet::Type.type(:install_ssh_keys).provide :ssh do
  desc 'install ssh keys'

  def exists?
    File.exist?("#{sshdir}/#{@resource[:authkey]}") && File.read("#{sshdir}/#{@resource[:authkey]}").grep(sshkey).any?
  end

  def create
    FileUtils.mkdir_p sshdir
    FileUtils.cp @resource[:keypath], sshdir
    FileUtils.cp @resource[:pub_keypath], sshdir
    FileUtils.chown_R Etc.getpwnam(@resource[:user]).uid, Etc.getpwnam(@resource[:user]).uid, sshdir
    FileUtils.chmod_R 0600, sshdir
    FileUtils.chmod 0700, sshdir
    File.open("#{sshdir}/#{@resource[:authkey]}", 'a') { |file| file.write sshkey }
  end

  def destroy
    FileUtils.rm @resource[:keypath]
    FileUtils.rm @resource[:pub_keypath]
    authkey = File.read("#{sshdir}/#{@resource[:authkey]}").gsub(/#{sshkey}\n?/, '')
    File.open("#{sshdir}/#{@resource[:authkey]}", 'w') { |file| file.puts authkey }
  end

  def sshdir
    File.join(File.expand_path("~#{@resource[:user]}"), '.ssh')
  end

  def sshkey
    File.read @resource[:pub_keypath]
  end
end
