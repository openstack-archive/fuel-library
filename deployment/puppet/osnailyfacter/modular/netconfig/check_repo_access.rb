#!/usr/bin/env ruby
require 'rubygems'
require 'hiera'

ENV['LANG'] = 'C'
$hiera = Hiera.new(:config => '/etc/hiera.yaml')

def check_repos(repos)
  urls = repos.map { |e| e['uri'] }
  urls.each do |url|
    command =`wget --delete-after --timeout=5 #{url}`
    command
    if $?.exitstatus !=0
      raise "
Was un-able to access repo #{url}.
Please check nodes access to all of the repos on the settings page"
    end
 end
end

repos = $hiera.lookup('repo_setup', false, {})['repos']
check_repos(repos)
