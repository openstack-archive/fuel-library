# At this point, it's an exact copy of the Blastwave stuff.
Puppet::Type.type(:package).provide :rpmforce, :parent => :rpm, :source => :rpm do
  desc "Package management using rpm --force option"

  commands :rpm => "rpm"

  def install
    super 
  rescue Puppet::ExecutionFailure
    rpm "-U", "--force", @resource[:source]
  end

end
