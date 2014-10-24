Puppet::Type.type(:service).provide(:dummy) do
  has_feature :enableable
  has_feature :refreshable

  def status
    :running
  end

  def start
    nil
  end

  def stop
    nil
  end

  def restart
    nil
  end

  def enabled?
    :true
  end

  def enable
    nil
  end

  def disable
    nil
  end
end