#!/usr/bin/env ruby
require 'hiera'

ENV['LANG'] = 'C'

hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
test_vm_image = hiera.lookup 'test_vm_image', {}, {}

raise 'Not test_vm_image data!' unless ( test_vm_image.is_a? Hash or test_vm_image.is_a? Array ) and test_vm_image.any?

# Check for old or new yaml 'test_vm_image' data format for
# backward compatibility.
test_vm_images = Array.new
if test_vm_image.is_a? Hash
  test_vm_images << test_vm_image
end

test_vm_images.each do |image|
  %w(
  disk_format
  img_path
  img_name
  os_name
  public
  container_format
  min_ram
  ).each do |f|
    raise "Data field '#{f}' is missing!" unless image[f]
  end
end

def image_list
  stdout = `. /root/openrc && glance image-list`
  return_code = $?.exitstatus
  images = []
  stdout.split("\n").each do |line|
    fields = line.split('|').map { |f| f.chomp.strip }
    next if fields[1] == 'ID'
    next unless fields[2]
    images << fields[2]
  end
  [ images, return_code ]
end

def image_create(image_hash)
  command = <<-EOF
. /root/openrc && /usr/bin/glance image-create \
--name '#{image_hash['img_name']}' \
--is-public '#{image_hash['public']}' \
--container-format='#{image_hash['container_format']}' \
--disk-format='#{image_hash['disk_format']}' \
--min-ram='#{image_hash['min_ram']}' \
#{image_hash['glance_properties']} \
--file '#{image_hash['img_path']}'
EOF
  puts command
  stdout = `#{command}`
  return_code = $?.exitstatus
  [ stdout, return_code ]
end

# check if Glance is onlin
# waited until the glance is started because when vCenter used as a glance
# backend launch may takes up to 1 minute.
5.times.each do |retries|
  sleep 10 if retries > 0
  break if image_list.last == 0
end
raise 'Could not get a list of glance images!' unless image_list.last == 0

images_for_upload = test_vm_images.clone

# check if image is already uploaded
images, return_code = image_list
test_vm_images.each do |image|
  if images.include? image['img_name'] and return_code == 0
    puts "Image '#{image['img_name']}' is already present!"
    images_for_upload.delete(image)
  end
end

images_for_upload do |image|
  # create an image
  stdout, return_code = image_create image

  if return_code == 0
    puts "Image '#{image['img_name']}' was uploaded from '#{image['img_path']}'"
  else
    puts "Image '#{image['img_name']}' uploaded from '#{image['img_path']}' have FAILED!"
    exit return_code
  end
  puts stdout
end
