require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new('spec')

task :publish_gem do
  require 'gem_publisher'
  gem = GemPublisher.publish_if_updated('puppet-syntax.gemspec', :rubygems)
  puts "Published #{gem}" if gem
end

task :default => [:spec]
