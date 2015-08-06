require 'puppet/parameter'

if Puppet.features.microsoft_windows?
  require 'win32/taskscheduler'
  require 'puppet/util/adsi'
end

Puppet::Type.type(:scheduled_task).provide(:win32_taskscheduler) do
  desc %q{This provider uses the win32-taskscheduler gem to manage scheduled
    tasks on Windows.

    Puppet requires version 0.2.1 or later of the win32-taskscheduler gem;
    previous versions can cause "Could not evaluate: The operation completed
    successfully" errors.}

  defaultfor :operatingsystem => :windows
  confine    :operatingsystem => :windows

  def self.instances
    Win32::TaskScheduler.new.tasks.collect do |job_file|
      job_title = File.basename(job_file, '.job')

      new(
        :provider => :win32_taskscheduler,
        :name     => job_title
      )
    end
  end

  def exists?
    Win32::TaskScheduler.new.exists? resource[:name]
  end

  def task
    return @task if @task

    @task ||= Win32::TaskScheduler.new
    @task.activate(resource[:name] + '.job') if exists?

    @task
  end

  def clear_task
    @task       = nil
    @triggers   = nil
  end

  def enabled
    task.flags & Win32::TaskScheduler::DISABLED == 0 ? :true : :false
  end

  def command
    task.application_name
  end

  def arguments
    task.parameters
  end

  def working_dir
    task.working_directory
  end

  def user
    account = task.account_information
    return 'system' if account == ''
    account
  end

  def trigger
    return @triggers if @triggers

    @triggers   = []
    task.trigger_count.times do |i|
      trigger = begin
                  task.trigger(i)
                rescue Win32::TaskScheduler::Error
                  # Win32::TaskScheduler can't handle all of the
                  # trigger types Windows uses, so we need to skip the
                  # unhandled types to prevent "puppet resource" from
                  # blowing up.
                  nil
                end
      next unless trigger and scheduler_trigger_types.include?(trigger['trigger_type'])

      puppet_trigger = {}
      case trigger['trigger_type']
      when Win32::TaskScheduler::TASK_TIME_TRIGGER_DAILY
        puppet_trigger['schedule'] = 'daily'
        puppet_trigger['every']    = trigger['type']['days_interval'].to_s
      when Win32::TaskScheduler::TASK_TIME_TRIGGER_WEEKLY
        puppet_trigger['schedule'] = 'weekly'
        puppet_trigger['every']    = trigger['type']['weeks_interval'].to_s
        puppet_trigger['on']       = days_of_week_from_bitfield(trigger['type']['days_of_week'])
      when Win32::TaskScheduler::TASK_TIME_TRIGGER_MONTHLYDATE
        puppet_trigger['schedule'] = 'monthly'
        puppet_trigger['months']   = months_from_bitfield(trigger['type']['months'])
        puppet_trigger['on']       = days_from_bitfield(trigger['type']['days'])
      when Win32::TaskScheduler::TASK_TIME_TRIGGER_MONTHLYDOW
        puppet_trigger['schedule']         = 'monthly'
        puppet_trigger['months']           = months_from_bitfield(trigger['type']['months'])
        puppet_trigger['which_occurrence'] = occurrence_constant_to_name(trigger['type']['weeks'])
        puppet_trigger['day_of_week']      = days_of_week_from_bitfield(trigger['type']['days_of_week'])
      when Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE
        puppet_trigger['schedule'] = 'once'
      end
      puppet_trigger['start_date'] = self.class.normalized_date("#{trigger['start_year']}-#{trigger['start_month']}-#{trigger['start_day']}")
      puppet_trigger['start_time'] = self.class.normalized_time("#{trigger['start_hour']}:#{trigger['start_minute']}")
      puppet_trigger['enabled']    = trigger['flags'] & Win32::TaskScheduler::TASK_TRIGGER_FLAG_DISABLED == 0
      puppet_trigger['index']      = i

      @triggers << puppet_trigger
    end
    @triggers = @triggers[0] if @triggers.length == 1

    @triggers
  end

  def user_insync?(current, should)
    return false unless current

    # Win32::TaskScheduler can return the 'SYSTEM' account as the
    # empty string.
    current = 'system' if current == ''

    # By comparing account SIDs we don't have to worry about case
    # sensitivity, or canonicalization of the account name.
    Puppet::Util::Windows::Security.name_to_sid(current) == Puppet::Util::Windows::Security.name_to_sid(should[0])
  end

  def trigger_insync?(current, should)
    should  = [should] unless should.is_a?(Array)
    current = [current] unless current.is_a?(Array)
    return false unless current.length == should.length

    current_in_sync = current.all? do |c|
      should.any? {|s| triggers_same?(c, s)}
    end

    should_in_sync = should.all? do |s|
      current.any? {|c| triggers_same?(c,s)}
    end

    current_in_sync && should_in_sync
  end

  def command=(value)
    task.application_name = value
  end

  def arguments=(value)
    task.parameters = value
  end

  def working_dir=(value)
    task.working_directory = value
  end

  def enabled=(value)
    if value == :true
      task.flags = task.flags & ~Win32::TaskScheduler::DISABLED
    else
      task.flags = task.flags | Win32::TaskScheduler::DISABLED
    end
  end

  def trigger=(value)
    desired_triggers = value.is_a?(Array) ? value : [value]
    current_triggers = trigger.is_a?(Array) ? trigger : [trigger]

    extra_triggers = []
    desired_to_search = desired_triggers.dup
    current_triggers.each do |current|
      if found = desired_to_search.find {|desired| triggers_same?(current, desired)}
        desired_to_search.delete(found)
      else
        extra_triggers << current['index']
      end
    end

    needed_triggers = []
    current_to_search = current_triggers.dup
    desired_triggers.each do |desired|
      if found = current_to_search.find {|current| triggers_same?(current, desired)}
        current_to_search.delete(found)
      else
        needed_triggers << desired
      end
    end

    extra_triggers.reverse_each do |index|
      task.delete_trigger(index)
    end

    needed_triggers.each do |trigger_hash|
      # Even though this is an assignment, the API for
      # Win32::TaskScheduler ends up appending this trigger to the
      # list of triggers for the task, while #add_trigger is only able
      # to replace existing triggers. *shrug*
      task.trigger = translate_hash_to_trigger(trigger_hash)
    end
  end

  def user=(value)
    self.fail("Invalid user: #{value}") unless Puppet::Util::Windows::Security.name_to_sid(value)

    if value.to_s.downcase != 'system'
      task.set_account_information(value, resource[:password])
    else
      # Win32::TaskScheduler treats a nil/empty username & password as
      # requesting the SYSTEM account.
      task.set_account_information(nil, nil)
    end
  end

  def create
    clear_task
    @task = Win32::TaskScheduler.new(resource[:name], dummy_time_trigger)

    self.command = resource[:command]

    [:arguments, :working_dir, :enabled, :trigger, :user].each do |prop|
      send("#{prop}=", resource[prop]) if resource[prop]
    end
  end

  def destroy
    Win32::TaskScheduler.new.delete(resource[:name] + '.job')
  end

  def flush
    unless resource[:ensure] == :absent
      self.fail('Parameter command is required.') unless resource[:command]
      task.save
      @task = nil
    end
  end

  def triggers_same?(current_trigger, desired_trigger)
    return false unless current_trigger['schedule'] == desired_trigger['schedule']
    return false if current_trigger.has_key?('enabled') && !current_trigger['enabled']

    desired = desired_trigger.dup

    desired['every']       ||= current_trigger['every']       if current_trigger.has_key?('every')
    desired['months']      ||= current_trigger['months']      if current_trigger.has_key?('months')
    desired['on']          ||= current_trigger['on']          if current_trigger.has_key?('on')
    desired['day_of_week'] ||= current_trigger['day_of_week'] if current_trigger.has_key?('day_of_week')

    translate_hash_to_trigger(current_trigger) == translate_hash_to_trigger(desired)
  end

  def self.normalized_date(date_string)
    date = Date.parse("#{date_string}")
    "#{date.year}-#{date.month}-#{date.day}"
  end

  def self.normalized_time(time_string)
    Time.parse("#{time_string}").strftime('%H:%M')
  end

  def dummy_time_trigger
    now = Time.now

    {
      'flags'                   => 0,
      'random_minutes_interval' => 0,
      'end_day'                 => 0,
      "end_year"                => 0,
      "trigger_type"            => 0,
      "minutes_interval"        => 0,
      "end_month"               => 0,
      "minutes_duration"        => 0,
      'start_year'              => now.year,
      'start_month'             => now.month,
      'start_day'               => now.day,
      'start_hour'              => now.hour,
      'start_minute'            => now.min,
      'trigger_type'            => Win32::TaskScheduler::ONCE,
    }
  end

  def translate_hash_to_trigger(puppet_trigger, user_provided_input=false)
    trigger = dummy_time_trigger

    if user_provided_input
      self.fail "'enabled' is read-only on triggers" if puppet_trigger.has_key?('enabled')
      self.fail "'index' is read-only on triggers"   if puppet_trigger.has_key?('index')
    end
    puppet_trigger.delete('index')

    if puppet_trigger.delete('enabled') == false
      trigger['flags'] |= Win32::TaskScheduler::TASK_TRIGGER_FLAG_DISABLED
    else
      trigger['flags'] &= ~Win32::TaskScheduler::TASK_TRIGGER_FLAG_DISABLED
    end

    extra_keys = puppet_trigger.keys.sort - ['schedule', 'start_date', 'start_time', 'every', 'months', 'on', 'which_occurrence', 'day_of_week']
    self.fail "Unknown trigger option(s): #{Puppet::Parameter.format_value_for_display(extra_keys)}" unless extra_keys.empty?
    self.fail "Must specify 'start_time' when defining a trigger" unless puppet_trigger['start_time']

    case puppet_trigger['schedule']
    when 'daily'
      trigger['trigger_type'] = Win32::TaskScheduler::DAILY
      trigger['type'] = {
        'days_interval' => Integer(puppet_trigger['every'] || 1)
      }
    when 'weekly'
      trigger['trigger_type'] = Win32::TaskScheduler::WEEKLY
      trigger['type'] = {
        'weeks_interval' => Integer(puppet_trigger['every'] || 1)
      }

      trigger['type']['days_of_week'] = if puppet_trigger['day_of_week']
                                          bitfield_from_days_of_week(puppet_trigger['day_of_week'])
                                        else
                                          scheduler_days_of_week.inject(0) {|day_flags,day| day_flags |= day}
                                        end
    when 'monthly'
      trigger['type'] = {
        'months' => bitfield_from_months(puppet_trigger['months'] || (1..12).to_a),
      }

      if puppet_trigger.keys.include?('on')
        if puppet_trigger.has_key?('day_of_week') or puppet_trigger.has_key?('which_occurrence')
          self.fail "Neither 'day_of_week' nor 'which_occurrence' can be specified when creating a monthly date-based trigger"
        end

        trigger['trigger_type'] = Win32::TaskScheduler::MONTHLYDATE
        trigger['type']['days'] = bitfield_from_days(puppet_trigger['on'])
      elsif puppet_trigger.keys.include?('which_occurrence') or puppet_trigger.keys.include?('day_of_week')
        self.fail 'which_occurrence cannot be specified as an array' if puppet_trigger['which_occurrence'].is_a?(Array)
        %w{day_of_week which_occurrence}.each do |field|
          self.fail "#{field} must be specified when creating a monthly day-of-week based trigger" unless puppet_trigger.has_key?(field)
        end

        trigger['trigger_type']         = Win32::TaskScheduler::MONTHLYDOW
        trigger['type']['weeks']        = occurrence_name_to_constant(puppet_trigger['which_occurrence'])
        trigger['type']['days_of_week'] = bitfield_from_days_of_week(puppet_trigger['day_of_week'])
      else
        self.fail "Don't know how to create a 'monthly' schedule with the options: #{puppet_trigger.keys.sort.join(', ')}"
      end
    when 'once'
      self.fail "Must specify 'start_date' when defining a one-time trigger" unless puppet_trigger['start_date']

      trigger['trigger_type'] = Win32::TaskScheduler::ONCE
    else
      self.fail "Unknown schedule type: #{puppet_trigger["schedule"].inspect}"
    end

    if start_date = puppet_trigger['start_date']
      start_date = Date.parse(start_date)
      self.fail "start_date must be on or after 1753-01-01" unless start_date >= Date.new(1753, 1, 1)

      trigger['start_year']  = start_date.year
      trigger['start_month'] = start_date.month
      trigger['start_day']   = start_date.day
    end

    start_time = Time.parse(puppet_trigger['start_time'])
    trigger['start_hour']   = start_time.hour
    trigger['start_minute'] = start_time.min

    trigger
  end

  def validate_trigger(value)
    value = [value] unless value.is_a?(Array)

    # translate_hash_to_trigger handles the same validation that we
    # would be doing here at the individual trigger level.
    value.each {|t| translate_hash_to_trigger(t, true)}

    true
  end

  private

  def bitfield_from_months(months)
    bitfield = 0

    months = [months] unless months.is_a?(Array)
    months.each do |month|
      integer_month = Integer(month) rescue nil
      self.fail 'Month must be specified as an integer in the range 1-12' unless integer_month == month.to_f and integer_month.between?(1,12)

      bitfield |= scheduler_months[integer_month - 1]
    end

    bitfield
  end

  def bitfield_from_days(days)
    bitfield = 0

    days = [days] unless days.is_a?(Array)
    days.each do |day|
      # The special "day" of 'last' is represented by day "number"
      # 32. 'last' has the special meaning of "the last day of the
      # month", no matter how many days there are in the month.
      day = 32 if day == 'last'

      integer_day = Integer(day)
      self.fail "Day must be specified as an integer in the range 1-31, or as 'last'" unless integer_day = day.to_f and integer_day.between?(1,32)

      bitfield |= 1 << integer_day - 1
    end

    bitfield
  end

  def bitfield_from_days_of_week(days_of_week)
    bitfield = 0

    days_of_week = [days_of_week] unless days_of_week.is_a?(Array)
    days_of_week.each do |day_of_week|
      bitfield |= day_of_week_name_to_constant(day_of_week)
    end

    bitfield
  end

  def months_from_bitfield(bitfield)
    months = []

    scheduler_months.each do |month|
      if bitfield & month != 0
        months << month_constant_to_number(month)
      end
    end

    months
  end

  def days_from_bitfield(bitfield)
    days = []

    i = 0
    while bitfield > 0
      if bitfield & 1 > 0
        # Day 32 has the special meaning of "the last day of the
        # month", no matter how many days there are in the month.
        days << (i == 31 ? 'last' : i + 1)
      end

      bitfield = bitfield >> 1
      i += 1
    end

    days
  end

  def days_of_week_from_bitfield(bitfield)
    days_of_week = []

    scheduler_days_of_week.each do |day_of_week|
      if bitfield & day_of_week != 0
        days_of_week << day_of_week_constant_to_name(day_of_week)
      end
    end

    days_of_week
  end

  def scheduler_trigger_types
    [
      Win32::TaskScheduler::TASK_TIME_TRIGGER_DAILY,
      Win32::TaskScheduler::TASK_TIME_TRIGGER_WEEKLY,
      Win32::TaskScheduler::TASK_TIME_TRIGGER_MONTHLYDATE,
      Win32::TaskScheduler::TASK_TIME_TRIGGER_MONTHLYDOW,
      Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE
    ]
  end

  def scheduler_days_of_week
    [
      Win32::TaskScheduler::SUNDAY,
      Win32::TaskScheduler::MONDAY,
      Win32::TaskScheduler::TUESDAY,
      Win32::TaskScheduler::WEDNESDAY,
      Win32::TaskScheduler::THURSDAY,
      Win32::TaskScheduler::FRIDAY,
      Win32::TaskScheduler::SATURDAY
    ]
  end

  def scheduler_months
    [
      Win32::TaskScheduler::JANUARY,
      Win32::TaskScheduler::FEBRUARY,
      Win32::TaskScheduler::MARCH,
      Win32::TaskScheduler::APRIL,
      Win32::TaskScheduler::MAY,
      Win32::TaskScheduler::JUNE,
      Win32::TaskScheduler::JULY,
      Win32::TaskScheduler::AUGUST,
      Win32::TaskScheduler::SEPTEMBER,
      Win32::TaskScheduler::OCTOBER,
      Win32::TaskScheduler::NOVEMBER,
      Win32::TaskScheduler::DECEMBER
    ]
  end

  def scheduler_occurrences
    [
      Win32::TaskScheduler::FIRST_WEEK,
      Win32::TaskScheduler::SECOND_WEEK,
      Win32::TaskScheduler::THIRD_WEEK,
      Win32::TaskScheduler::FOURTH_WEEK,
      Win32::TaskScheduler::LAST_WEEK
    ]
  end

  def day_of_week_constant_to_name(constant)
    case constant
    when Win32::TaskScheduler::SUNDAY;    'sun'
    when Win32::TaskScheduler::MONDAY;    'mon'
    when Win32::TaskScheduler::TUESDAY;   'tues'
    when Win32::TaskScheduler::WEDNESDAY; 'wed'
    when Win32::TaskScheduler::THURSDAY;  'thurs'
    when Win32::TaskScheduler::FRIDAY;    'fri'
    when Win32::TaskScheduler::SATURDAY;  'sat'
    end
  end

  def day_of_week_name_to_constant(name)
    case name
    when 'sun';   Win32::TaskScheduler::SUNDAY
    when 'mon';   Win32::TaskScheduler::MONDAY
    when 'tues';  Win32::TaskScheduler::TUESDAY
    when 'wed';   Win32::TaskScheduler::WEDNESDAY
    when 'thurs'; Win32::TaskScheduler::THURSDAY
    when 'fri';   Win32::TaskScheduler::FRIDAY
    when 'sat';   Win32::TaskScheduler::SATURDAY
    end
  end

  def month_constant_to_number(constant)
    month_num = 1
    while constant >> month_num - 1 > 1
      month_num += 1
    end
    month_num
  end

  def occurrence_constant_to_name(constant)
    case constant
    when Win32::TaskScheduler::FIRST_WEEK;  'first'
    when Win32::TaskScheduler::SECOND_WEEK; 'second'
    when Win32::TaskScheduler::THIRD_WEEK;  'third'
    when Win32::TaskScheduler::FOURTH_WEEK; 'fourth'
    when Win32::TaskScheduler::LAST_WEEK;   'last'
    end
  end

  def occurrence_name_to_constant(name)
    case name
    when 'first';  Win32::TaskScheduler::FIRST_WEEK
    when 'second'; Win32::TaskScheduler::SECOND_WEEK
    when 'third';  Win32::TaskScheduler::THIRD_WEEK
    when 'fourth'; Win32::TaskScheduler::FOURTH_WEEK
    when 'last';   Win32::TaskScheduler::LAST_WEEK
    end
  end
end
