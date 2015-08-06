require "puppet-syntax/version"
require "puppet-syntax/manifests"
require "puppet-syntax/templates"
require "puppet-syntax/hiera"

module PuppetSyntax
  @exclude_paths = []
  @future_parser = false
  @hieradata_paths = ["**/data/**/*.yaml", "hieradata/**/*.yaml", "hiera*.yaml"]
  @fail_on_deprecation_notices = true

  class << self
    attr_accessor :exclude_paths, :future_parser, :hieradata_paths, :fail_on_deprecation_notices
  end
end
