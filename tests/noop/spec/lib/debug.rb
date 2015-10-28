module Noop::Debug
  def debug(msg)
    puts msg if ENV['SPEC_PUPPET_DEBUG']
  end

  def status_report(example)
    report = <<-eos
      =============================================
      OS:       #{os_name}
      YAML:     #{astute_yaml_base}
      Spec:     #{current_spec example}
      Manifest: #{manifest_path}
      Node:     #{fqdn}
      Role:     #{role}
      =============================================
    eos
    report
  end
end
