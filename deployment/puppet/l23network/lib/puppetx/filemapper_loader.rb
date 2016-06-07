begin
  require 'puppetx/filemapper'
rescue LoadError
  # try to load the filemapper directy
  require_relative '../../../filemapper/lib/puppetx/filemapper'
end
