module Puppet::Parser::Functions
  newfunction(
    :generate_plugins_repos,
    :type  => :rvalue,
    :arity => 1,
    :docs  => <<-EOS
Transforms plugins array provided by astute.yaml to a form easily
usable with create_resources and the puppetlabs/apt's apt::source type.
    EOS
  ) do |args|
    plugins = args[0]

    raise(Puppet::ParseError, "generate_plugins_repos(): Requires array to " +
          "work with") unless plugins.is_a?(Array)

    result = {}

    plugins.each do |plugin|
      plugin['repositories'].each do |repo|
        result.store repo['name'], {
          'repos'    => repo['section'],
          'release'  => repo['suite'],
          'location' => repo['uri'],
        }
      end
    end

    return result
  end
end
