Puppet::Type.type(:postgres_config).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do

  def section
    ""
  end

  def setting
    resource[:name]
  end

  def separator
    '='
  end

  def file_path
    '/var/lib/pgsql/9.3/data/postgresql.conf'
  end

end
