source 'https://rubygems.org'

group :development, :test do
  gem 'mime-types', '2.6.2',                  :require => 'false' # 3.0+ requires ruby 2.0

end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  # TODO(aschultz): remove this version when 4 is supported
  gem 'puppet', '~> 3.8', :require => false
end
