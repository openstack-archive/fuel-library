require 'puppet/file_serving/terminus_helper'
require 'puppet/indirector/terminus'

class Puppet::Indirector::DirectFileServer < Puppet::Indirector::Terminus

  include Puppet::FileServing::TerminusHelper

  def find(request)
    return nil unless Puppet::FileSystem::File.exist?(request.key)
    instance = model.new(request.key)
    instance.links = request.options[:links] if request.options[:links]
    instance
  end

  def search(request)
    return nil unless Puppet::FileSystem::File.exist?(request.key)
    path2instances(request, request.key)
  end
end
