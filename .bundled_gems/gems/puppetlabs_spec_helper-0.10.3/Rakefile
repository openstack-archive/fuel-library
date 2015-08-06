require 'rake'
require 'rake/packagetask'
require 'rubygems/package_task'

task :default do
    sh %{rake -T}
end

require 'fileutils'

def version
  require 'puppetlabs_spec_helper/version'
  PuppetlabsSpecHelper::Version::STRING
end

namespace :package do
  desc "Create the gem"
  task :gem do
    spec = Gem::Specification.load("puppetlabs_spec_helper.gemspec")
    Dir.mkdir("pkg") rescue nil
    if Gem::Version.new(`gem -v`) >= Gem::Version.new("2.0.0.a")
      Gem::Package.build(spec)
    else
      Gem::Builder.new(spec).build
    end
    FileUtils.move("puppetlabs_spec_helper-#{version}.gem", "pkg")
  end
end

desc "Cleanup pkg directory"
task :clean do
  FileUtils.rm_rf("pkg")
end
