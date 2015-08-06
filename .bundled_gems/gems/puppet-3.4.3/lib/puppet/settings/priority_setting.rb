require 'puppet/settings/base_setting'

# A setting that represents a scheduling priority, and evaluates to an
# OS-specific priority level.
class Puppet::Settings::PrioritySetting < Puppet::Settings::BaseSetting
  PRIORITY_MAP =
    if Puppet::Util::Platform.windows?
      require 'win32/process'
      {
        :high    => Process::HIGH_PRIORITY_CLASS,
        :normal  => Process::NORMAL_PRIORITY_CLASS,
        :low     => Process::BELOW_NORMAL_PRIORITY_CLASS,
        :idle    => Process::IDLE_PRIORITY_CLASS
      }
    else
      {
        :high    => -10,
        :normal  => 0,
        :low     => 10,
        :idle    => 19
      }
    end

  def type
    :priority
  end

  def munge(value)
    return unless value

    case
    when value.is_a?(Integer)
      value
    when (value.is_a?(String) and value =~ /\d+/)
      value.to_i
    when (value.is_a?(String) and PRIORITY_MAP[value.to_sym])
      PRIORITY_MAP[value.to_sym]
    else
      raise Puppet::Settings::ValidationError, "Invalid priority format '#{value.inspect}' for parameter: #{@name}"
    end
  end
end
