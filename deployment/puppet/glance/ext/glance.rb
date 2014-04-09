#!/usr/bin/env ruby
#
# test that we can upload and download files
#
require 'open3'
require 'fileutils'

keystone_public = '127.0.0.1'
image_dir='/tmp/images'

ENV['OS_USERNAME']='admin'
ENV['OS_TENANT_NAME']='admin'
ENV['OS_PASSWORD']='ChangeMe'
ENV['OS_AUTH_URL']='http://127.0.0.1:5000/v2.0/'
ENV['OS_REGION_NAME']='RegionOne'

FileUtils.mkdir_p(image_dir)
Dir.chdir(image_dir) do |dir|

  kernel_id = nil
  initrd_id = nil

  remote_image_url='http://smoser.brickies.net/ubuntu/ttylinux-uec/ttylinux-uec-amd64-12.1_2.6.35-22_1.tar.gz; tar -zxvf ttylinux-uec-amd64-12.1_2.6.35-22_1.tar.gz'

  wget_command = "wget #{remote_image_url}"

  Open3.popen3(wget_command) do |stdin, stdout, stderr|
    puts "wget stdout: #{stdout.read}"
    puts "wget stderr: #{stderr.read}"
  end

  add_kernel='disk_format=aki container_format=aki < ttylinux-uec-amd64-12.1_2.6.35-22_1-vmlinuz'
  kernel_name='tty-linux-kernel'
  kernel_format='aki'

  add_kernel_command="glance add name='#{kernel_name}' disk_format='#{kernel_format}' container_format=#{kernel_format} < ttylinux-uec-amd64-12.1_2.6.35-22_1-vmlinuz"

  Open3.popen3(add_kernel_command) do |stdin, stdout, stderr|
    stdout = stdout.read.split("\n")
    stdout.each do |line|
      if line =~ /Added new image with ID: (\w+)/
        kernel_id = $1
      end
    end
    puts stderr.read
    puts stdout
  end

  raise(Exception, 'Did not add kernel successfully') unless kernel_id

  initrd_id = nil
  add_initrd_command="glance add name='tty-linux-ramdisk' disk_format=ari container_format=ari < ttylinux-uec-amd64-12.1_2.6.35-22_1-loader"

  Open3.popen3(add_initrd_command) do |stdin, stdout, stderr|
    stdout = stdout.read.split("\n")
    stdout.each do |line|
      if line =~ /Added new image with ID: (\w+)/
        initrd_id = $1
      end
    end
    puts stderr.read
    puts stdout
  end

  raise(Exception, 'Did not add initrd successfully') unless initrd_id

  add_image_command="glance add name='tty-linux' disk_format=ami container_format=ami kernel_id=#{kernel_id} ramdisk_id=#{initrd_id} < ttylinux-uec-amd64-12.1_2.6.35-22_1.img"

  Open3.popen3(add_image_command) do |stdin, stdout, stderr|
    stdout = stdout.read.split("\n")
    stdout.each do |line|
      if line =~ /Added new image with ID: (\w+)/
        kernel_id = $1
      end
    end
    puts stderr.read
    puts stdout
  end

  get_index='glance index'

  Open3.popen3(get_index) do |stdin, stdout, stderr|
    puts stdout.read
    puts stderr.read
  end
end
