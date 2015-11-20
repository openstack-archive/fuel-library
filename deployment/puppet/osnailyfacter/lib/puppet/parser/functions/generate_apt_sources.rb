module Puppet::Parser::Functions
  newfunction(:generate_apt_sources, :type => :rvalue) do |args|
    raise(Puppet::ParseError, "generate_apt_sources(): Wrong number of " +
          "arguments given (#{args.size}, expected 1)") if args.size != 1

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
