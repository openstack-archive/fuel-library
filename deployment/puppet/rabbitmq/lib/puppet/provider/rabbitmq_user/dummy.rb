Puppet::Type.type(:rabbitmq_user).provide(:dummy) do

  def create
    nil
  end

  def destroy
    nil
  end

  def exists?
    true
  end

  def tags
    []
  end

  def tags=(tags)
    nil
  end

  def admin
    false
  end

  def admin=(state)
    nil
  end

end
