module Noop::Debug
  def debug(msg)
    puts msg if ENV['SPEC_PUPPET_DEBUG']
  end

  def status_report(context)
    <<-eos
      =============================================
      OS:       #{current_os context}
      YAML:     #{astute_yaml_base}
      Spec:     #{current_spec context}
      Manifest: #{manifest_path}
      Node:     #{fqdn}
      Role:     #{role}
      =============================================
    eos
  end
end
