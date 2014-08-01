Puppet::Parser::Functions::newfunction(:create_cinder_backends, :type => :rvalue, :doc => <<-EOS
Create cinder backends from cinder_backends structure and return the array of enabled backends
EOS
) do |argv|
  if argv.length < 1
    raise Puppet::ParseError, "No arguments"
  end

  cinder_backends = argv[0]

  if !cinder_backends.is_a? Hash
    raise Puppet::ParseError, "Argument must be cinder_backends structure!"
  end
  enabled_backends = []

  cinder_backends.each do |k,v|
    resource_type = "cinder::backend::#{k}"
    resource_params = v
    unless v.is_a? Hash
       raise Puppet::ParseError, "Cinder backends structure is invalid"
    end
    function_create_resources [resource_type, resource_params]
    v.each do |k,v|
      enabled_backends << k
    end

  end
  enabled_backends

end

