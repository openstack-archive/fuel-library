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
and Codename. Repositories with no or empty priority are skipped.
      EOS
  ) do |args|
    repositories = args[0]
    raise Puppet::ParseError, "generate_apt_pins(): Requires array to work with" unless repositories.is_a? Array

    result = {}
    repositories.each do |repo|
      next unless repo['priority']
      uri = URI.parse "#{repo['uri']}/dists/#{repo['suite']}/Release"
      response = nil
      retry_count = 3

      (1..retry_count).each do |try|
        begin
          response = Net::HTTP.start(uri.host, uri.port, :open_timeout => 180, :read_timeout => 600) {|http| http.request(uri.request_uri)}
          debug "Processing '#{uri}' finished."
          break
        rescue Timeout::Error => exception
          info "Attempt '#{try}' of '#{retry_count}' has failed: #{exception.message}"
          raise exception if try >= retry_count
          sleep 5
        end
      end

      unless response.kind_of? Net::HTTPSuccess
        fail "GET HTTP request to: '#{uri.to_s}' have failed! (#{response.code} #{response.message})"
      end

      value_map = {
          'originator' => /^Origin: (.*)/,
          'label'      => /^Label: (.*)/,
          'release'    => /^Suite: (.*)/,
          'codename'   => /^Codename: (.*)/,
      }

      repo_data = {
          'priority' => repo['priority'],
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
