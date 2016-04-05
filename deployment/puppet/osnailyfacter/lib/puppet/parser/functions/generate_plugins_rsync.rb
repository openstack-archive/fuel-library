module Puppet::Parser::Functions
  newfunction(
    :generate_plugins_rsync,
    :type  => :rvalue,
    :arity => 1,
    :docs  => <<-EOS
Transforms plugins array provided by astute.yaml to a form easily
usable with create_resources and the puppetlabs/rsync's rsync::get type.
    EOS
  ) do |args|
    plugins = args[0]

    raise(Puppet::ParseError, "generate_plugins_rsync(): Requires array to " +
          "work with") unless plugins.is_a?(Array)

    result = {}

    plugins.each do |plugin|
      plugin['scripts'].each do |script|
        result.store script['local_path'], {
          'path'      => script['local_path'],
          'source'    => script['remote_url'],
          'recursive' => 'true',
        }
      end
    end

    return result
  end
end
