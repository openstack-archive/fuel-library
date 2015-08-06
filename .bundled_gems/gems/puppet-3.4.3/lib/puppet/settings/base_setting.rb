require 'puppet/settings/errors'

# The base setting type
class Puppet::Settings::BaseSetting
  attr_accessor :name, :desc, :section, :default, :call_on_define, :call_hook
  attr_reader :short

  def self.available_call_hook_values
    [:on_define_and_write, :on_initialize_and_write, :on_write_only]
  end

  def call_on_define
    Puppet.deprecation_warning "call_on_define has been deprecated.  Please use call_hook_on_define?"
    call_hook_on_define?
  end

  def call_on_define=(value)
    if value
      Puppet.deprecation_warning ":call_on_define has been changed to :call_hook => :on_define_and_write. Please change #{name}."
      @call_hook = :on_define_and_write
    else
      Puppet.deprecation_warning ":call_on_define => :false has been changed to :call_hook => :on_write_only. Please change #{name}."
      @call_hook = :on_write_only
    end
  end

  def call_hook=(value)
    if value.nil?
      Puppet.warning "Setting :#{name} :call_hook is nil, defaulting to :on_write_only"
      value ||= :on_write_only
    end
    raise ArgumentError, "Invalid option #{value} for call_hook" unless self.class.available_call_hook_values.include? value
    @call_hook = value
  end

  def call_hook_on_define?
    call_hook == :on_define_and_write
  end

  def call_hook_on_initialize?
    call_hook == :on_initialize_and_write
  end

  #added as a proper method, only to generate a deprecation warning
  #and return value from
  def setbycli
    Puppet.deprecation_warning "Puppet.settings.setting(#{name}).setbycli is deprecated. Use Puppet.settings.set_by_cli?(#{name}) instead."
    @settings.set_by_cli?(name)
  end

  def setbycli=(value)
    Puppet.deprecation_warning "Puppet.settings.setting(#{name}).setbycli= is deprecated. You should not manually set that values were specified on the command line."
    @settings.set_value(name, @settings[name], :cli) if value
    raise ArgumentError, "Cannot unset setbycli" unless value
  end

  # get the arguments in getopt format
  def getopt_args
    if short
      [["--#{name}", "-#{short}", GetoptLong::REQUIRED_ARGUMENT]]
    else
      [["--#{name}", GetoptLong::REQUIRED_ARGUMENT]]
    end
  end

  # get the arguments in OptionParser format
  def optparse_args
    if short
      ["--#{name}", "-#{short}", desc, :REQUIRED]
    else
      ["--#{name}", desc, :REQUIRED]
    end
  end

  def has_hook?
    respond_to? :handle
  end

  def hook=(block)
    meta_def :handle, &block
  end

  # Create the new element.  Pretty much just sets the name.
  def initialize(args = {})
    unless @settings = args.delete(:settings)
      raise ArgumentError.new("You must refer to a settings object")
    end

    # explicitly set name prior to calling other param= methods to provide meaningful feedback during
    # other warnings
    @name = args[:name] if args.include? :name

    #set the default value for call_hook
    @call_hook = :on_write_only if args[:hook] and not args[:call_hook]

    raise ArgumentError, "Cannot reference :call_hook for :#{@name} if no :hook is defined" if args[:call_hook] and not args[:hook]

    args.each do |param, value|
      method = param.to_s + "="
      raise ArgumentError, "#{self.class} (setting '#{args[:name]}') does not accept #{param}" unless self.respond_to? method

      self.send(method, value)
    end

    raise ArgumentError, "You must provide a description for the #{self.name} config option" unless self.desc
  end

  def iscreated
    @iscreated = true
  end

  def iscreated?
    @iscreated
  end

  # short name for the celement
  def short=(value)
    raise ArgumentError, "Short names can only be one character." if value.to_s.length != 1
    @short = value.to_s
  end

  def default(check_application_defaults_first = false)
    return @default unless check_application_defaults_first
    return @settings.value(name, :application_defaults, true) || @default
  end

  # Convert the object to a config statement.
  def to_config
    require 'puppet/util/docs'
    # Scrub any funky indentation; comment out description.
    str = Puppet::Util::Docs.scrub(@desc).gsub(/^/, "# ") + "\n"

    # Add in a statement about the default.
    str << "# The default value is '#{default(true)}'.\n" if default(true)

    # If the value has not been overridden, then print it out commented
    # and unconverted, so it's clear that that's the default and how it
    # works.
    value = @settings.value(self.name)

    if value != @default
      line = "#{@name} = #{value}"
    else
      line = "# #{@name} = #{@default}"
    end

    str << (line + "\n")

    # Indent
    str.gsub(/^/, "    ")
  end

  # Retrieves the value, or if it's not set, retrieves the default.
  def value
    @settings.value(self.name)
  end

  # Modify the value when it is first evaluated
  def munge(value)
    value
  end
end
