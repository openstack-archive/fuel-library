require 'puppet-syntax'
require 'rake'
require 'rake/tasklib'

module PuppetSyntax
  class RakeTask < ::Rake::TaskLib
    def initialize(*args)
      desc 'Syntax check Puppet manifests and templates'
      task :syntax => [
        'syntax:check_puppetlabs_spec_helper',
        'syntax:manifests',
        'syntax:templates',
        'syntax:hiera',
      ]

      namespace :syntax do
        task :check_puppetlabs_spec_helper do
          psh_present = Rake::Task[:syntax].actions.any? { |a|
            a.inspect.match(/puppetlabs_spec_helper\/rake_tasks\.rb:\d+/)
          }

          if psh_present
            warn <<-EOS
[WARNING] A conflicting :syntax rake task has been defined by
puppetlabs_spec_helper/rake_tasks. You should either disable this or upgrade
to puppetlabs_spec_helper >= 0.8.0 which now uses puppet-syntax.
            EOS
          end
        end

        desc 'Syntax check Puppet manifests'
        task :manifests do |t|
          $stderr.puts "---> #{t.name}"
          files = FileList["**/*.pp"]
          files.reject! { |f| File.directory?(f) }
          files = files.exclude(*PuppetSyntax.exclude_paths)

          c = PuppetSyntax::Manifests.new
          output, has_errors = c.check(files)
          print "#{output.join("\n")}\n" unless output.empty?
          fail if has_errors || ( output.any? && PuppetSyntax.fail_on_deprecation_notices )
        end

        desc 'Syntax check Puppet templates'
        task :templates do |t|
          $stderr.puts "---> #{t.name}"
          files = FileList["**/templates/**/*"]
          files.reject! { |f| File.directory?(f) }
          files = files.exclude(*PuppetSyntax.exclude_paths)

          c = PuppetSyntax::Templates.new
          errors = c.check(files)
          fail errors.join("\n") unless errors.empty?
        end

        desc 'Syntax check Hiera config files'
        task :hiera => [
          'syntax:hiera:yaml',
        ]

        namespace :hiera do
          task :yaml do |t|
            $stderr.puts "---> #{t.name}"
            files = FileList.new(PuppetSyntax.hieradata_paths)
            files.reject! { |f| File.directory?(f) }
            files = files.exclude(*PuppetSyntax.exclude_paths)

            c = PuppetSyntax::Hiera.new
            errors = c.check(files)
            fail errors.join("\n") unless errors.empty?
          end
        end
      end
    end
  end
end

PuppetSyntax::RakeTask.new
