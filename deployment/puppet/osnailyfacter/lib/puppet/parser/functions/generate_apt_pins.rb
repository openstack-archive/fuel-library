require 'net/http'
require 'uri'

module Puppet::Parser::Functions
  newfunction(
      :generate_apt_pins,
      :type  => :rvalue,
      :arity => 1,
      :doc   => <<-EOS
Takes an array of repositories (in form used in astute.yaml) as argument.
Returns a hash compatible with the apt::pin type provided by puppetlabs/apt
module. It requires working connectivity to given repositories - the function
parses repositories' Release files to obtain fields like Origin, Label, Suite
and Codename.
      EOS
  ) do |args|
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
        repo_data[key] = $1 if response.body =~ regexp
      end

      result.store repo['name'], repo_data
    end

    p result
    result
  end
end
