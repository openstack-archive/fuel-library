module RSpec::Puppet
  module DefineExampleGroup
    include RSpec::Puppet::ManifestMatchers
    include RSpec::Puppet::Support

    def catalogue
      @catalogue ||= load_catalogue(:define)
    end
  end
end
