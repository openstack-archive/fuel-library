module Puppet::Parser::Functions
  newfunction(
    :generate_apt_sources,
    :type  => :rvalue,
    :arity => 1,
    :docs  => <<-EOS
Transforms repo_setup['repos'] array provided by astute.yaml to a form easily
usable with create_resources and the puppetlabs/apt's apt::source type.
    EOS
  ) do |args|
    repositories = args[0]

    raise(Puppet::ParseError, "generate_apt_sources(): Requires array to " +
          "work with") unless repositories.is_a?(Array)

    result = {}

    repositories.each do |repo|
      result.store repo['name'], {
        'repos'    => repo['section'],
        'release'  => repo['suite'],
        'location' => repo['uri'],
      }
    end

    return result
  end
end
