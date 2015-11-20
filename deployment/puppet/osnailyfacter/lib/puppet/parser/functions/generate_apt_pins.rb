require 'net/http'
require 'uri'

module Puppet::Parser::Functions
  newfunction(:generate_apt_pins, :type => :rvalue) do |args|
    raise(Puppet::ParseError, "generate_apt_pins(): Wrong number of " +
          "arguments given (#{args.size}, expected 1)") if args.size != 1

    repositories = args[0]

    raise(Puppet::ParseError, "generate_apt_pins(): Requires array to " +
          "work with") unless repositories.is_a?(Array)

    result = {}

    repositories.each do |repo|
      next if not repo['priority']
      release_uri = "#{repo['uri']}/dists/#{repo['suite']}/Release"

      uri = URI.parse(release_uri)
      release = Net::HTTP.get_response(uri).body

      result.store repo['name'], {
        'priority'   => repo['priority'],
        'originator' => release.match(/^Origin: (.*)/)[1],
        'label'      => release.match(/^Label: (.*)/)[1],
        'release'    => release.match(/^Suite: (.*)/)[1],
        'codename'   => release.match(/^Codename: (.*)/)[1],
      }
    end

    return result
  end
end
