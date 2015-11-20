module Puppet::Parser::Functions
  newfunction(
    :generate_apt_sources,
    :type => :rvalue,
    :arity => 1,
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
