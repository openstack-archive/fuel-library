Puppet::Type.newtype(:glance_image) do
  desc <<-EOT
    This allows manifests to declare an image to be
    stored in glance.

    glance_image { "Ubuntu 12.04 cloudimg amd64":
      ensure           => present,
      name             => "Ubuntu 12.04 cloudimg amd64"
      is_public        => yes,
      container_format => ovf,
      disk_format      => 'qcow2',
      source           => 'http://uec-images.ubuntu.com/releases/precise/release/ubuntu-12.04-server-cloudimg-amd64-disk1.img'
    }

    Known problems / limitations:
      * All images are managed by the glance service. 
        This means that since users are unable to manage their own images via this type,
        is_public is really of no use. You can probably hide images this way but that's all.
      * As glance image names do not have to be unique, you must ensure that your glance 
        repository does not have any duplicate names prior to using this.
      * Ensure this is run on the same server as the glance-api service.

  EOT

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The image name'
    newvalues(/.*/)
  end

  newproperty(:id) do
    desc 'The unique id of the image'
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:location) do
    desc "The permanent location of the image. Optional"
    newvalues(/\S+/)
  end

  newproperty(:is_public) do
    desc "Whether the image is public or not. Default true"
    newvalues(/(y|Y)es/, /(n|N)o/)
    defaultto('Yes')
    munge do |v|
      v.to_s.capitalize
    end
  end

  newproperty(:container_format) do
    desc "The format of the container"
    newvalues(:ami, :ari, :aki, :bare, :ovf)
  end

  newproperty(:disk_format) do
    desc "The format of the disk"
    newvalues(:ami, :ari, :aki, :vhd, :vmd, :raw, :qcow2, :vdi, :iso)
  end

  newparam(:source) do
    desc "The source of the image to import from"
    newvalues(/\S+/)
  end

  # Require the Glance service to be running
  autorequire(:service) do
    ['glance']
  end

end


