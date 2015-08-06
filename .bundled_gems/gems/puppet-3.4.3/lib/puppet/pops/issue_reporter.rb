class Puppet::Pops::IssueReporter

  # @param acceptor [Puppet::Pops::Validation::Acceptor] the acceptor containing reported issues
  # @option options [String] :message (nil) A message text to use as prefix in a single Error message
  # @option options [Boolean] :emit_warnings (false) A message text to use as prefix in a single Error message
  # @option options [Boolean] :emit_errors (true) whether errors should be emitted or only given message
  # @option options [Exception] :exception_class (Puppet::ParseError) The exception to raise
  #
  def self.assert_and_report(acceptor, options)
    return unless acceptor

    max_errors = Puppet[:max_errors]
    max_warnings = Puppet[:max_warnings] + 1
    max_deprecations = Puppet[:max_deprecations] + 1
    emit_warnings = options[:emit_warnings] || false
    emit_errors = options[:emit_errors] || true
    emit_message = options[:message]
    emit_exception = options[:exception_class] || Puppet::ParseError

    # If there are warnings output them
    warnings = acceptor.warnings
    if emit_warnings && warnings.size > 0
      formatter = Puppet::Pops::Validation::DiagnosticFormatterPuppetStyle.new
      emitted_w = 0
      emitted_dw = 0
      acceptor.warnings.each do |w|
        if w.severity == :deprecation
          # Do *not* call Puppet.deprecation_warning it is for internal deprecation, not
          # deprecation of constructs in manifests! (It is not designed for that purpose even if
          # used throughout the code base).
          #
          Puppet.warning(formatter.format(w)) if emitted_dw < max_deprecations
          emitted_dw += 1
        else
          Puppet.warning(formatter.format(w)) if emitted_w < max_warnings
          emitted_w += 1
        end
        break if emitted_w > max_warnings && emitted_dw > max_deprecations # but only then
      end
    end

    # If there were errors, report the first found. Use a puppet style formatter.
    errors = acceptor.errors
    if errors.size > 0
      unless emit_errors
        raise emit_exception.new(emit_message)
      end
      formatter = Puppet::Pops::Validation::DiagnosticFormatterPuppetStyle.new
      if errors.size == 1 || max_errors <= 1
        # raise immediately
        raise emit_exception.new(format_with_prefix(emit_message, formatter.format(errors[0])))
      end
      emitted = 0
      if emit_message
        Puppet.err(emit_message)
      end
      errors.each do |e|
        Puppet.err(formatter.format(e))
        emitted += 1
        break if emitted >= max_errors
      end
      warnings_message = (emit_warnings && warnings.size > 0) ? ", and #{warnings.size} warnings" : ""
      giving_up_message = "Found #{errors.size} errors#{warnings_message}. Giving up"
      exception = emit_exception.new(giving_up_message)
      exception.file = errors[0].file
      raise exception
    end
    parse_result
  end

  def self.format_with_prefix(prefix, message)
    return message unless prefix
    [prefix, message].join(' ')
  end
end