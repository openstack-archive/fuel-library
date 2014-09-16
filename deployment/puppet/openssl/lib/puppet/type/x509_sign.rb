require 'pathname'
Puppet::Type.newtype(:x509_sign) do
  desc 'Sign certificate'

  ensurable

  newparam(:path, :namevar => true) do
    desc 'The path to the newly signed certificate'
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:template) do
    desc 'The template to use'

    defaultto do
      path = Pathname.new(@resource[:path])
      "#{path.dirname}/#{path.basename(path.extname)}.cnf"
    end

    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:infile) do
    desc 'The name of the file containing certificate request.'

    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
    end

  end

  autorequire(:file) do
    self[:template]
  end
end
