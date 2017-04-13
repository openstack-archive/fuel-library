module Puppet::Parser::Functions
  newfunction(
      :generate_glance_images,
      :type  => :rvalue,
      :arity => -2,
      :doc   => <<-EOS
Takes an array of glance images (in form used in astute.yaml) as argument.
Returns a hash compatible with the glance_image type provided by the glance
module.
      EOS
  ) do |args|
    images, extra_properties = args
    raise Puppet::ParseError, "generate_glance_images(): Requires an array to work with" unless images.is_a? Array

    extra_properties ||= {}

    images.reduce({}) do |result, image|
      raise Puppet::ParseError, "generate_glance_images(): Requires an array of hashes" unless image.is_a? Hash

      params = {
        'container_format' => image['container_format'],
        'disk_format'      => image['disk_format'],
        'is_public'        => image['public'],
        'min_ram'          => image['min_ram'],
        'source'           => image['img_path'],
        'properties'       => image['properties'].merge(extra_properties),
      }

      result.merge(image['img_name'] => params)
    end
  end
end
