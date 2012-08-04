# Load the Glance provider library to help
require File.join(File.dirname(__FILE__), '..','..','..', 'puppet/provider/glance')

Puppet::Type.type(:glance_image).provide(
  :glance,
  :parent => Puppet::Provider::Glance
) do
  desc <<-EOT
    Glance provider to manage glance_image type.

    Assumes that the glance-api service is on the same host and is working.
  EOT

  commands :glance => 'glance'

  def self.prefetch(resource)
    # rebuild the cache for every puppet run
    @image_hash = nil
  end

  def self.image_hash
    @image_hash ||= build_image_hash
  end

  def image_hash
    self.class.image_hash
  end

  def self.instances
    image_hash.collect do |k, v|
      new(:name => k)
    end
  end

  def create
    stdin = nil
    if resource[:source]
      # copy_from cannot handle file://
      if resource[:source] =~ /^\// # local file
        location = "< #{resource[:source]}"
        stdin = true
      else
        location = "copy_from=#{resource[:source]}"
      end
    # location cannot handle file://
    # location does not import, so no sense in doing anything more than this
    elsif resource[:location]
      location = "location=#{resource[:location]}"
    else
      raise(Puppet::Error, "Must specify either source or location")
    end
    if stdin
      auth_glance_stdin('add', "name='#{resource[:name]}'", "is_public=#{resource[:is_public]}", "container_format=#{resource[:container_format]}", "disk_format=#{resource[:disk_format]}", location)
    else
      auth_glance('add', "name='#{resource[:name]}'", "is_public=#{resource[:is_public]}", "container_format=#{resource[:container_format]}", "disk_format=#{resource[:disk_format]}", location)
    end
  end

  def exists?
    image_hash[resource[:name]]
  end

  def destroy
    auth_glance('delete', '-f', image_hash[resource[:name]]['id'])
  end

  def location
    image_hash[resource[:name]]['location']
  end

  def location=(value)
    auth_glance('update', image_hash[resource[:name]]['id'], "location=#{value}")
  end

  def is_public
    image_hash[resource[:name]]['public']
  end

  def is_public=(value)
    auth_glance('update', image_hash[resource[:name]]['id'], "is_public=#{value}")
  end

  def disk_format
    image_hash[resource[:name]]['disk format']
  end

  def disk_format=(value)
    auth_glance('update', image_hash[resource[:name]]['id'], "disk_format=#{value}")
  end

  def container_format
    image_hash[resource[:name]]['container format']
  end

  def container_format=(value)
    auth_glance('update', image_hash[resource[:name]]['id'], "container_format=#{value}")
  end

  def id
    image_hash[resource[:name]]['id']
  end

  private 
    def self.build_image_hash
      hash = {}
      list_glance_images.each do |image|
        attrs = get_glance_image_attrs(image)
        hash[attrs['name'].to_s] = attrs
      end
      hash
    end
end

