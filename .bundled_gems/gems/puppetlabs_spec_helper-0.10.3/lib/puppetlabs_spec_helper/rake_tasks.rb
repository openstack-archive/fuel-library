require 'rake'
require 'rspec/core/rake_task'
require 'yaml'

task :default => [:help]

desc "Run spec tests on an existing fixtures directory"
RSpec::Core::RakeTask.new(:spec_standalone) do |t|
  t.rspec_opts = ['--color']
  t.pattern = 'spec/{classes,defines,unit,functions,hosts,integration}/**/*_spec.rb'
end

desc "Run beaker acceptance tests"
RSpec::Core::RakeTask.new(:beaker) do |t|
  t.rspec_opts = ['--color']
  t.pattern = 'spec/acceptance'
end

desc "Generate code coverage information"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

# This is a helper for the self-symlink entry of fixtures.yml
def source_dir
  Dir.pwd
end

def fixtures(category)
  begin
    fixtures = YAML.load_file(".fixtures.yml")["fixtures"]
  rescue Errno::ENOENT
    return {}
  end

  if not fixtures
    abort("malformed fixtures.yml")
  end

  result = {}
  if fixtures.include? category and fixtures[category] != nil
    fixtures[category].each do |fixture, opts|
      if opts.instance_of?(String)
        source = opts
        target = "spec/fixtures/modules/#{fixture}"
        real_source = eval('"'+source+'"')
        result[real_source] = target
      elsif opts.instance_of?(Hash)
        target = "spec/fixtures/modules/#{fixture}"
        real_source = eval('"'+opts["repo"]+'"')
        result[real_source] = { "target" => target, "ref" => opts["ref"], "branch" => opts["branch"], "scm" => opts["scm"] }
      end
    end
  end
  return result
end

def clone_repo(scm, remote, target, ref=nil, branch=nil)
  args = []
  case scm
  when 'hg'
    args.push('clone')
    args.push('-u', ref) if ref
    args.push(remote, target)
  when 'git'
    args.push('clone')
    args.push('--depth 1') unless ref
    args.push('-b', branch) if branch
    args.push(remote, target)
  else
      fail "Unfortunately #{scm} is not supported yet"
  end
  system("#{scm} #{args.flatten.join ' '}")
end

def revision(scm, target, ref)
  args = []
  case scm
  when 'hg'
    args.push('update', 'clean', '-r', ref)
  when 'git'
    args.push('reset', '--hard', ref)
  else
      fail "Unfortunately #{scm} is not supported yet"
  end
  system("cd #{target} && #{scm} #{args.flatten.join ' '}")
end

desc "Create the fixtures directory"
task :spec_prep do
  # Ruby only sets File::ALT_SEPARATOR on Windows and Rubys standard library
  # uses this to check for Windows
  is_windows = !!File::ALT_SEPARATOR
  puppet_symlink_available = false
  begin
    require 'puppet'
    puppet_symlink_available = Puppet::FileSystem.respond_to?(:symlink)
  rescue
  end


  fixtures("repositories").each do |remote, opts|
    scm = 'git'
    if opts.instance_of?(String)
      target = opts
    elsif opts.instance_of?(Hash)
      target = opts["target"]
      ref = opts["ref"]
      scm = opts["scm"] if opts["scm"]
      branch = opts["branch"] if opts["branch"]
    end

    unless File::exists?(target) || clone_repo(scm, remote, target, ref, branch)
      fail "Failed to clone #{scm} repository #{remote} into #{target}"
    end
    revision(scm, target, ref) if ref
  end

  FileUtils::mkdir_p("spec/fixtures/modules")
  fixtures("symlinks").each do |source, target|
    if is_windows
      fail "Cannot symlink on Windows unless using at least Puppet 3.5" if !puppet_symlink_available
      Puppet::FileSystem::exist?(target) || Puppet::FileSystem::symlink(source, target)
    else
      File::exists?(target) || FileUtils::ln_sf(source, target)
    end
  end

  fixtures("forge_modules").each do |remote, opts|
    if opts.instance_of?(String)
      target = opts
      ref = ""
    elsif opts.instance_of?(Hash)
      target = opts["target"]
      ref = "--version #{opts['ref']}"
    end
    next if File::exists?(target)
    unless system("puppet module install " + ref + \
                  " --ignore-dependencies" \
                  " --force" \
                  " --target-dir spec/fixtures/modules #{remote}")
      fail "Failed to install module #{remote} to #{target}"
    end
  end

  FileUtils::mkdir_p("spec/fixtures/manifests")
  FileUtils::touch("spec/fixtures/manifests/site.pp")
end

desc "Clean up the fixtures directory"
task :spec_clean do
  fixtures("repositories").each do |remote, opts|
    if opts.instance_of?(String)
      target = opts
    elsif opts.instance_of?(Hash)
      target = opts["target"]
    end
    FileUtils::rm_rf(target)
  end

  fixtures("forge_modules").each do |remote, opts|
    if opts.instance_of?(String)
      target = opts
    elsif opts.instance_of?(Hash)
      target = opts["target"]
    end
    FileUtils::rm_rf(target)
  end

  fixtures("symlinks").each do |source, target|
    FileUtils::rm_f(target)
  end

  if File.zero?("spec/fixtures/manifests/site.pp")
    FileUtils::rm_f("spec/fixtures/manifests/site.pp")
  end

end

desc "Run spec tests in a clean fixtures directory"
task :spec do
  Rake::Task[:spec_prep].invoke
  Rake::Task[:spec_standalone].invoke
  Rake::Task[:spec_clean].invoke
end

desc "List available beaker nodesets"
task :beaker_nodes do
  Dir['spec/acceptance/nodesets/*.yml'].sort!.select { |node|
    node.slice!('.yml')
    puts File.basename(node)
  }
end

desc "Build puppet module package"
task :build do
  # This will be deprecated once puppet-module is a face.
  begin
    Gem::Specification.find_by_name('puppet-module')
  rescue Gem::LoadError, NoMethodError
    require 'puppet/face'
    pmod = Puppet::Face['module', :current]
    pmod.build('./')
  end
end

desc "Clean a built module package"
task :clean do
  FileUtils.rm_rf("pkg/")
end

require 'puppet-lint/tasks/puppet-lint'
# Must clear as it will not override the existing puppet-lint rake task since we require to import for
# the PuppetLint::RakeTask
Rake::Task[:lint].clear
# Relative is not able to be set within the context of PuppetLint::RakeTask
PuppetLint.configuration.relative = true
PuppetLint::RakeTask.new(:lint) do |config|
  config.fail_on_warnings = true
  config.disable_checks = [
      '80chars',
      'class_inherits_from_params_class',
      'class_parameter_defaults',
      'documentation',
      'single_quote_string_with_variables']
  config.ignore_paths = ["tests/**/*.pp", "vendor/**/*.pp","examples/**/*.pp" "spec/**/*.pp", "pkg/**/*.pp"]
end

require 'puppet-syntax/tasks/puppet-syntax'
PuppetSyntax.exclude_paths ||= []
PuppetSyntax.exclude_paths << "spec/fixtures/**/*"
PuppetSyntax.exclude_paths << "pkg/**/*"
PuppetSyntax.exclude_paths << "vendor/**/*"
PuppetSyntax.future_parser = true if ENV['FUTURE_PARSER'] == 'yes'

desc "Check syntax of Ruby files and call :syntax and :metadata"
task :validate do
  Dir['lib/**/*.rb'].each do |lib_file|
    sh "ruby -c #{lib_file}"
  end

  Rake::Task[:syntax].invoke
  Rake::Task[:metadata].invoke if File.exist?('metadata.json')
end

desc "Validate metadata.json file"
task :metadata do
  begin
    require 'metadata_json_lint'
    sh "metadata-json-lint metadata.json"
  rescue LoadError => e
    warn "Skipping metadata validation; the metadata-json-lint gem was not found"
  end
end

desc "Display the list of available rake tasks"
task :help do
  system("rake -T")
end
