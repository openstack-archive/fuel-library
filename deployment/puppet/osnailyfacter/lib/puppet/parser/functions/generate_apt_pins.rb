require 'net/http'
require 'uri'

module Puppet::Parser::Functions
  newfunction(
      :generate_apt_pins,
      :type => :rvalue,
      :arity => 1,
  ) do |args|
    raise Puppet::ParseError, "generate_apt_pins(): Wrong number of arguments given (#{args.size}, expected 1)" if args.size < 1
    repositories = args[0]
    raise Puppet::ParseError, "generate_apt_pins(): Requires array to work with" unless repositories.is_a? Array

    result = {}
    repositories.each do |repo|
      next unless repo['priority']
      uri = URI.parse "#{repo['uri']}/dists/#{repo['suite']}/Release"
      response = Net::HTTP.get_response uri

      unless response.kind_of? Net::HTTPSuccess
        fail "GET HTTP request to: '#{uri.to_s}' have failed! (#{response.code} #{response.message})"
      end

      value_map = {
          'originator' => /^Origin: (.*)/,
          'label' => /^Label: (.*)/,
          'release' => /^Suite: (.*)/,
          'codename' => /^Codename: (.*)/,
      }
      repo_data = {
          'priority'   => repo['priority'],
      }
      value_map.each do |key, regexp|
        repo_data[key] = $1 if  response.body =~ regexp
      end
      result.store repo['name'], repo_data
    end
    p result
    result
  end
end
