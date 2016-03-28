#!/usr/bin/env ruby
require 'hiera'

ENV['LANG'] = 'C'

cid = ARGV[0]

hiera = Hiera.new(:config => '/etc/hiera.yaml')
glanced = hiera.lookup 'glance', {} , {}
management_vip = hiera.lookup 'management_vip', nil, {}
auth_addr = hiera.lookup 'service_endpoint', "#{management_vip}", {}
tenant_name = glanced['tenant'].nil? ? "services" : glanced['tenant']
user_name = glanced['user'].nil? ? "glance" : glanced['user']
endpoint_type = glanced['endpoint_type'].nil? ? "internalURL" : glanced['endpoint_type']
region_name = hiera.lookup 'region', 'RegionOne', {}
master_ip = hiera.lookup 'master_ip', nil, {}
ssl_hash = hiera.lookup 'use_ssl', {}, {}

if ssl_hash['keystone_internal']
    auth_proto = 'https'
    auth_addr = ssl_hash['keystone_internal_hostname'] || auth_addr
else
    auth_proto = 'http'
end

ENV['OS_TENANT_NAME']="#{tenant_name}"
ENV['OS_USERNAME']="#{user_name}"
ENV['OS_PASSWORD']="#{glanced['user_password']}"
ENV['OS_AUTH_URL']="#{auth_proto}://#{auth_addr}:5000/v2.0"
ENV['OS_ENDPOINT_TYPE'] = "#{endpoint_type}"
ENV['OS_REGION_NAME']="#{region_name}"

ironic_images = [
{"os_name"=>"ironic-deploy-linux",
 "img_location"=>"http://#{master_ip}:8080/bootstrap/ironic/#{cid}/vmlinuz",
 "container_format"=>"aki",
 "min_ram"=>2048,
 "disk_format"=>"aki",
 "glance_properties"=>"",
 "img_name"=>"ironic-deploy-linux",
 "public"=>"true",
 "protected"=>"true",
},
{"os_name"=>"ironic-deploy-initramfs",
 "img_location"=>"http://#{master_ip}:8080/bootstrap/ironic/#{cid}/initrd.img",
 "container_format"=>"ari",
 "min_ram"=>2048,
 "disk_format"=>"ari",
 "glance_properties"=>"",
 "img_name"=>"ironic-deploy-initramfs",
 "public"=>"true",
 "protected"=>"true",
},
{"os_name"=>"ironic-deploy-squashfs",
 "img_location"=>"http://#{master_ip}:8080/bootstrap/ironic/#{cid}/root.squashfs",
 "container_format"=>"ari",
 "min_ram"=>2048,
 "disk_format"=>"ari",
 "glance_properties"=>"",
 "img_name"=>"ironic-deploy-squashfs",
 "public"=>"true",
 "protected"=>"true",
},
]

ironic_images.each do |image|
  %w(
  disk_format
  img_location
  img_name
  os_name
  public
  protected
  container_format
  min_ram
  ).each do |f|
    raise "Data field '#{f}' is missing!" unless image[f]
  end
end

def image_list
  stdout = `glance image-list`
  return_code = $?.exitstatus
  images = []
  stdout.split("\n").each do |line|
    fields = line.split('|').map { |f| f.chomp.strip }
    next if fields[1] == 'ID'
    next unless fields[2]
    images << fields[2]
  end
  {:images => images, :exit_code => return_code}
end

def image_create(image_hash)
  command = <<-EOF
/usr/bin/glance image-create \
--name '#{image_hash['img_name']}' \
--visibility '#{image_hash['visibility']}' \
--is-protected '#{image_hash['protected']}' \
--container-format='#{image_hash['container_format']}' \
--disk-format='#{image_hash['disk_format']}' \
--min-ram='#{image_hash['min_ram']}' \
#{image_hash['glance_properties']} \
--copy-from '#{image_hash['img_location']}'
EOF
  puts command
  stdout = `#{command}`
  return_code = $?.exitstatus
  [ stdout, return_code ]
end

# check if Glance is online
# waited until the glance is started because when vCenter used as a glance
# backend launch may takes up to 1 minute.
def wait_for_glance
  5.times.each do |retries|
    sleep 10 if retries > 0
    return if image_list[:exit_code] == 0
  end
  raise 'Could not get a list of glance images!'
end

# upload image to Glance
# if it have not been already uploaded
def upload_image(image)
  list_of_images = image_list
  if list_of_images[:images].include?(image['img_name']) && list_of_images[:exit_code] == 0
    puts "Image '#{image['img_name']}' is already present!"
    return 0
  end

  # convert old API v1 'public' property to API v2 'visibility' property
  if image['public'] == 'true'
    image['visibility'] = 'public'
  else
    image['visibility'] = 'private'
  end

  stdout, return_code = image_create(image)
  if return_code == 0
    puts "Image '#{image['img_name']}' was uploaded from '#{image['img_location']}'"
  else
    puts "Image '#{image['img_name']}' upload from '#{image['img_location']}' have FAILED!"
  end
  puts stdout
  return return_code
end

########################

wait_for_glance
errors = 0

ironic_images.each do |image|
  errors += upload_image(image)
end

exit 1 unless errors == 0
