require 'rubygems'
require 'serverspec'
require 'pathname'
require 'facter'
require 'puppet'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

Puppet.parse_config

if Puppet[:libdir] && !Facter.search_path.include?(Puppet[:libdir])
  Facter.search(Puppet[:libdir])
end

facts = {}
Facter.list.each do |fact|
  facts[fact] = Facter.value(fact) || ''
end

Facter.list.map { |fact| [fact, Facter.value(fact) || ''].flatten }

RSpec.configure do |c|
  if ENV['ASK_SUDO_PASSWORD']
    require 'highline/import'
    c.sudo_password = ask("Enter sudo password: ") { |q| q.echo = false }
  else
    c.sudo_password = ENV['SUDO_PASSWORD']
  end
  attr_set facts
  c.before :all do
    ENV['LANG'] = 'C'
  end
end
