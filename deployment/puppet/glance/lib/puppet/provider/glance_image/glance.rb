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
        :is_public        => attrs['is_public'],
        :container_format => attrs['container_format'],
        :id               => attrs['id'],
        :disk_format      => attrs['disk_format']
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
    if resource[:source]
      # copy_from cannot handle file://
      if resource[:source] =~ /^\// # local file
        location = "--file=#{resource[:source]}"
      else
        location = "--copy-from=#{resource[:source]}"
      end
    # location cannot handle file://
    # location does not import, so no sense in doing anything more than this
    elsif resource[:location]
      location = "--location=#{resource[:location]}"
    else
      raise(Puppet::Error, "Must specify either source or location")
    end
    results = auth_glance('image-create', "--name=#{resource[:name]}", "--is-public=#{resource[:is_public]}", "--container-format=#{resource[:container_format]}", "--disk-format=#{resource[:disk_format]}", location)

    id = nil

    # Check the old behavior of the python-glanceclient
    if results =~ /Added new image with ID: (\S+)/
      id = $1
    else # the new behavior doesn't print the status, so parse the table
      results_array = parse_table(results)
      results_array.each do |result|
        if result["Property"] == "id"
          id = result["Value"]
        end
      end
    end

    if id
      @property_hash = {
        :ensure           => :present,
        :name             => resource[:name],
        :is_public        => resource[:is_public],
        :container_format => resource[:container_format],
        :disk_format      => resource[:disk_format],
        :id               => id
      }
    else
        fail("did not get expected message from image creation, got #{results}")
    end
  end

  def destroy
    auth_glance('image-delete', id)
    @property_hash[:ensure] = :absent
  end

  def location=(value)
    auth_glance('image-update', id, "--location=#{value}")
  end

  def is_public=(value)
    auth_glance('image-update', id, "--is-public=#{value}")
  end

  def disk_format=(value)
    auth_glance('image-update', id, "--disk-format=#{value}")
  end

  def container_format=(value)
    auth_glance('image-update', id, "--container-format=#{value}")
  end

  def id=(id)
    fail('id is read only')
  end

end
