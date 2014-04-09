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

  mk_resource_methods

  def self.instances
    list_glance_images.collect do |image|
      attrs = get_glance_image_attrs(image)
      new(
        :ensure           => :present,
        :name             => attrs['name'],
        :is_public        => attrs['public'],
        :container_format => attrs['container format'],
        :id               => attrs['id'],
        :disk_format      => attrs['disk format']
      )
    end
  end

  def self.prefetch(resources)
    images = instances
    resources.keys.each do |name|
      if provider = images.find{ |pkg| pkg.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
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
      result = auth_glance_stdin('add', "name=#{resource[:name]}", "is_public=#{resource[:is_public]}", "container_format=#{resource[:container_format]}", "disk_format=#{resource[:disk_format]}", location)
    else
      results = auth_glance('add', "name=#{resource[:name]}", "is_public=#{resource[:is_public]}", "container_format=#{resource[:container_format]}", "disk_format=#{resource[:disk_format]}", location)
    end
    if results =~ /Added new image with ID: (\S+)/
      @property_hash = {
        :ensure           => :present,
        :name             => resource[:name],
        :is_public        => resource[:is_public],
        :container_format => resource[:container_format],
        :disk_format      => resource[:disk_format],
        :id               => $1
      }
    else
      fail("did not get expected message from image creation, got #{results}")
    end
  end

  def destroy
    auth_glance('delete', id)
    @property_hash[:ensure] = :absent
  end

  def location=(value)
    auth_glance('update', id, "location=#{value}")
  end

  def is_public=(value)
    auth_glance('update', id, "is_public=#{value}")
  end

  def disk_format=(value)
    auth_glance('update', id, "disk_format=#{value}")
  end

  def container_format=(value)
    auth_glance('update', id, "container_format=#{value}")
  end

  def id=(id)
    fail('id is read only')
  end

end
