class Puppet::Provider::Mysql < Puppet::Provider
  def connection_options
    cmd_array = []
    if @resource[:host]
      cmd_array = [
        "--host=#{@resource[:host]}",
        "--port=#{@resource[:port]}",
        "--user=#{@resource[:authorized_user]}",
        "--password=#{@resource[:authorized_pass]}",
      ]
    end
    cmd_array
  end
end