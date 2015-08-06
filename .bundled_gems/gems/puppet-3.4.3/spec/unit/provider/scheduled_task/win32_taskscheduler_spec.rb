#! /usr/bin/env ruby
require 'spec_helper'

require 'win32/taskscheduler' if Puppet.features.microsoft_windows?

shared_examples_for "a trigger that handles start_date and start_time" do
  let(:trigger) do
    described_class.new(
      :name => 'Shared Test Task',
      :command => 'C:\Windows\System32\notepad.exe'
    ).translate_hash_to_trigger(trigger_hash)
  end

  before :each do
    Win32::TaskScheduler.any_instance.stubs(:save)
  end

  describe 'the given start_date' do
    before :each do
      trigger_hash['start_time'] = '00:00'
    end

    def date_component
      {
        'start_year'  => trigger['start_year'],
        'start_month' => trigger['start_month'],
        'start_day'   => trigger['start_day']
      }
    end

    it 'should be able to be specified in ISO 8601 calendar date format' do
      trigger_hash['start_date'] = '2011-12-31'

      date_component.should == {
        'start_year'  => 2011,
        'start_month' => 12,
        'start_day'   => 31
      }
    end

    it 'should fail if before 1753-01-01' do
      trigger_hash['start_date'] = '1752-12-31'

      expect { date_component }.to raise_error(
        Puppet::Error,
        'start_date must be on or after 1753-01-01'
      )
    end

    it 'should succeed if on 1753-01-01' do
      trigger_hash['start_date'] = '1753-01-01'

      date_component.should == {
        'start_year'  => 1753,
        'start_month' => 1,
        'start_day'   => 1
      }
    end

    it 'should succeed if after 1753-01-01' do
      trigger_hash['start_date'] = '1753-01-02'

      date_component.should == {
        'start_year'  => 1753,
        'start_month' => 1,
        'start_day'   => 2
      }
    end
  end

  describe 'the given start_time' do
    before :each do
      trigger_hash['start_date'] = '2011-12-31'
    end

    def time_component
      {
        'start_hour'   => trigger['start_hour'],
        'start_minute' => trigger['start_minute']
      }
    end

    it 'should be able to be specified as a 24-hour "hh:mm"' do
      trigger_hash['start_time'] = '17:13'

      time_component.should == {
        'start_hour'   => 17,
        'start_minute' => 13
      }
    end

    it 'should be able to be specified as a 12-hour "hh:mm am"' do
      trigger_hash['start_time'] = '3:13 am'

      time_component.should == {
        'start_hour'   => 3,
        'start_minute' => 13
      }
    end

    it 'should be able to be specified as a 12-hour "hh:mm pm"' do
      trigger_hash['start_time'] = '3:13 pm'

      time_component.should == {
        'start_hour'   => 15,
        'start_minute' => 13
      }
    end
  end
end

describe Puppet::Type.type(:scheduled_task).provider(:win32_taskscheduler), :if => Puppet.features.microsoft_windows? do
  before :each do
    Puppet::Type.type(:scheduled_task).stubs(:defaultprovider).returns(described_class)
  end

  describe 'when retrieving' do
    before :each do
      @mock_task = mock
      @mock_task.responds_like(Win32::TaskScheduler.new)
      described_class.any_instance.stubs(:task).returns(@mock_task)

      Win32::TaskScheduler.stubs(:new).returns(@mock_task)
    end
    let(:resource) { Puppet::Type.type(:scheduled_task).new(:name => 'Test Task', :command => 'C:\Windows\System32\notepad.exe') }

    describe 'the triggers for a task' do
      describe 'with only one trigger' do
        before :each do
          @mock_task.expects(:trigger_count).returns(1)
        end

        it 'should handle a single daily trigger' do
          @mock_task.expects(:trigger).with(0).returns({
            'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_DAILY,
            'start_year'   => 2011,
            'start_month'  => 9,
            'start_day'    => 12,
            'start_hour'   => 13,
            'start_minute' => 20,
            'flags'        => 0,
            'type'         => { 'days_interval' => 2 },
          })

          resource.provider.trigger.should == {
            'start_date' => '2011-9-12',
            'start_time' => '13:20',
            'schedule'   => 'daily',
            'every'      => '2',
            'enabled'    => true,
            'index'      => 0,
          }
        end

        it 'should handle a single weekly trigger' do
          scheduled_days_of_week = Win32::TaskScheduler::MONDAY |
                                   Win32::TaskScheduler::WEDNESDAY |
                                   Win32::TaskScheduler::FRIDAY |
                                   Win32::TaskScheduler::SUNDAY
          @mock_task.expects(:trigger).with(0).returns({
            'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_WEEKLY,
            'start_year'   => 2011,
            'start_month'  => 9,
            'start_day'    => 12,
            'start_hour'   => 13,
            'start_minute' => 20,
            'flags'        => 0,
            'type'         => {
              'weeks_interval' => 2,
              'days_of_week'   => scheduled_days_of_week
            }
          })

          resource.provider.trigger.should == {
            'start_date' => '2011-9-12',
            'start_time' => '13:20',
            'schedule'   => 'weekly',
            'every'      => '2',
            'on'         => ['sun', 'mon', 'wed', 'fri'],
            'enabled'    => true,
            'index'      => 0,
          }
        end

        it 'should handle a single monthly date-based trigger' do
          scheduled_months = Win32::TaskScheduler::JANUARY |
                             Win32::TaskScheduler::FEBRUARY |
                             Win32::TaskScheduler::AUGUST |
                             Win32::TaskScheduler::SEPTEMBER |
                             Win32::TaskScheduler::DECEMBER
          #                1   3        5        15        'last'
          scheduled_days = 1 | 1 << 2 | 1 << 4 | 1 << 14 | 1 << 31
          @mock_task.expects(:trigger).with(0).returns({
            'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_MONTHLYDATE,
            'start_year'   => 2011,
            'start_month'  => 9,
            'start_day'    => 12,
            'start_hour'   => 13,
            'start_minute' => 20,
            'flags'        => 0,
            'type'         => {
              'months' => scheduled_months,
              'days'   => scheduled_days
            }
          })

          resource.provider.trigger.should == {
            'start_date' => '2011-9-12',
            'start_time' => '13:20',
            'schedule'   => 'monthly',
            'months'     => [1, 2, 8, 9, 12],
            'on'         => [1, 3, 5, 15, 'last'],
            'enabled'    => true,
            'index'      => 0,
          }
        end

        it 'should handle a single monthly day-of-week-based trigger' do
          scheduled_months = Win32::TaskScheduler::JANUARY |
                             Win32::TaskScheduler::FEBRUARY |
                             Win32::TaskScheduler::AUGUST |
                             Win32::TaskScheduler::SEPTEMBER |
                             Win32::TaskScheduler::DECEMBER
          scheduled_days_of_week = Win32::TaskScheduler::MONDAY |
                                   Win32::TaskScheduler::WEDNESDAY |
                                   Win32::TaskScheduler::FRIDAY |
                                   Win32::TaskScheduler::SUNDAY
          @mock_task.expects(:trigger).with(0).returns({
            'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_MONTHLYDOW,
            'start_year'   => 2011,
            'start_month'  => 9,
            'start_day'    => 12,
            'start_hour'   => 13,
            'start_minute' => 20,
            'flags'        => 0,
            'type'         => {
              'months'       => scheduled_months,
              'weeks'        => Win32::TaskScheduler::FIRST_WEEK,
              'days_of_week' => scheduled_days_of_week
            }
          })

          resource.provider.trigger.should == {
            'start_date'       => '2011-9-12',
            'start_time'       => '13:20',
            'schedule'         => 'monthly',
            'months'           => [1, 2, 8, 9, 12],
            'which_occurrence' => 'first',
            'day_of_week'      => ['sun', 'mon', 'wed', 'fri'],
            'enabled'          => true,
            'index'            => 0,
          }
        end

        it 'should handle a single one-time trigger' do
          @mock_task.expects(:trigger).with(0).returns({
            'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE,
            'start_year'   => 2011,
            'start_month'  => 9,
            'start_day'    => 12,
            'start_hour'   => 13,
            'start_minute' => 20,
            'flags'        => 0,
          })

          resource.provider.trigger.should == {
            'start_date' => '2011-9-12',
            'start_time' => '13:20',
            'schedule'   => 'once',
            'enabled'    => true,
            'index'      => 0,
          }
        end
      end

      it 'should handle multiple triggers' do
        @mock_task.expects(:trigger_count).returns(3)
        @mock_task.expects(:trigger).with(0).returns({
          'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE,
          'start_year'   => 2011,
          'start_month'  => 10,
          'start_day'    => 13,
          'start_hour'   => 14,
          'start_minute' => 21,
          'flags'        => 0,
        })
        @mock_task.expects(:trigger).with(1).returns({
          'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE,
          'start_year'   => 2012,
          'start_month'  => 11,
          'start_day'    => 14,
          'start_hour'   => 15,
          'start_minute' => 22,
          'flags'        => 0,
        })
        @mock_task.expects(:trigger).with(2).returns({
          'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE,
          'start_year'   => 2013,
          'start_month'  => 12,
          'start_day'    => 15,
          'start_hour'   => 16,
          'start_minute' => 23,
          'flags'        => 0,
        })

        resource.provider.trigger.should =~ [
          {
            'start_date' => '2011-10-13',
            'start_time' => '14:21',
            'schedule'   => 'once',
            'enabled'    => true,
            'index'      => 0,
          },
          {
            'start_date' => '2012-11-14',
            'start_time' => '15:22',
            'schedule'   => 'once',
            'enabled'    => true,
            'index'      => 1,
          },
          {
            'start_date' => '2013-12-15',
            'start_time' => '16:23',
            'schedule'   => 'once',
            'enabled'    => true,
            'index'      => 2,
          }
        ]
      end

      it 'should skip triggers Win32::TaskScheduler cannot handle' do
        @mock_task.expects(:trigger_count).returns(3)
        @mock_task.expects(:trigger).with(0).returns({
          'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE,
          'start_year'   => 2011,
          'start_month'  => 10,
          'start_day'    => 13,
          'start_hour'   => 14,
          'start_minute' => 21,
          'flags'        => 0,
        })
        @mock_task.expects(:trigger).with(1).raises(
          Win32::TaskScheduler::Error.new('Unhandled trigger type!')
        )
        @mock_task.expects(:trigger).with(2).returns({
          'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE,
          'start_year'   => 2013,
          'start_month'  => 12,
          'start_day'    => 15,
          'start_hour'   => 16,
          'start_minute' => 23,
          'flags'        => 0,
        })

        resource.provider.trigger.should =~ [
          {
            'start_date' => '2011-10-13',
            'start_time' => '14:21',
            'schedule'   => 'once',
            'enabled'    => true,
            'index'      => 0,
          },
          {
            'start_date' => '2013-12-15',
            'start_time' => '16:23',
            'schedule'   => 'once',
            'enabled'    => true,
            'index'      => 2,
          }
        ]
      end

      it 'should skip trigger types Puppet does not handle' do
        @mock_task.expects(:trigger_count).returns(3)
        @mock_task.expects(:trigger).with(0).returns({
          'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE,
          'start_year'   => 2011,
          'start_month'  => 10,
          'start_day'    => 13,
          'start_hour'   => 14,
          'start_minute' => 21,
          'flags'        => 0,
        })
        @mock_task.expects(:trigger).with(1).returns({
          'trigger_type' => Win32::TaskScheduler::TASK_EVENT_TRIGGER_AT_LOGON,
        })
        @mock_task.expects(:trigger).with(2).returns({
          'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE,
          'start_year'   => 2013,
          'start_month'  => 12,
          'start_day'    => 15,
          'start_hour'   => 16,
          'start_minute' => 23,
          'flags'        => 0,
        })

        resource.provider.trigger.should =~ [
          {
            'start_date' => '2011-10-13',
            'start_time' => '14:21',
            'schedule'   => 'once',
            'enabled'    => true,
            'index'      => 0,
          },
          {
            'start_date' => '2013-12-15',
            'start_time' => '16:23',
            'schedule'   => 'once',
            'enabled'    => true,
            'index'      => 2,
          }
        ]
      end
    end

    it 'should get the working directory from the working_directory on the task' do
      @mock_task.expects(:working_directory).returns('C:\Windows\System32')

      resource.provider.working_dir.should == 'C:\Windows\System32'
    end

    it 'should get the command from the application_name on the task' do
      @mock_task.expects(:application_name).returns('C:\Windows\System32\notepad.exe')

      resource.provider.command.should == 'C:\Windows\System32\notepad.exe'
    end

    it 'should get the command arguments from the parameters on the task' do
      @mock_task.expects(:parameters).returns('these are my arguments')

      resource.provider.arguments.should == 'these are my arguments'
    end

    it 'should get the user from the account_information on the task' do
      @mock_task.expects(:account_information).returns('this is my user')

      resource.provider.user.should == 'this is my user'
    end

    describe 'whether the task is enabled' do
      it 'should report tasks with the disabled bit set as disabled' do
        @mock_task.stubs(:flags).returns(Win32::TaskScheduler::DISABLED)

        resource.provider.enabled.should == :false
      end

      it 'should report tasks without the disabled bit set as enabled' do
        @mock_task.stubs(:flags).returns(~Win32::TaskScheduler::DISABLED)

        resource.provider.enabled.should == :true
      end

      it 'should not consider triggers for determining if the task is enabled' do
        @mock_task.stubs(:flags).returns(~Win32::TaskScheduler::DISABLED)
        @mock_task.stubs(:trigger_count).returns(1)
        @mock_task.stubs(:trigger).with(0).returns({
          'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE,
          'start_year'   => 2011,
          'start_month'  => 10,
          'start_day'    => 13,
          'start_hour'   => 14,
          'start_minute' => 21,
          'flags'        => Win32::TaskScheduler::TASK_TRIGGER_FLAG_DISABLED,
        })

        resource.provider.enabled.should == :true
      end
    end
  end

  describe '#exists?' do
    before :each do
      @mock_task = mock
      @mock_task.responds_like(Win32::TaskScheduler.new)
      described_class.any_instance.stubs(:task).returns(@mock_task)

      Win32::TaskScheduler.stubs(:new).returns(@mock_task)
    end
    let(:resource) { Puppet::Type.type(:scheduled_task).new(:name => 'Test Task', :command => 'C:\Windows\System32\notepad.exe') }

    it "should delegate to Win32::TaskScheduler using the resource's name" do
      @mock_task.expects(:exists?).with('Test Task').returns(true)

      resource.provider.exists?.should == true
    end
  end

  describe '#clear_task' do
    before :each do
      @mock_task     = mock
      @new_mock_task = mock
      @mock_task.responds_like(Win32::TaskScheduler.new)
      @new_mock_task.responds_like(Win32::TaskScheduler.new)
      Win32::TaskScheduler.stubs(:new).returns(@mock_task, @new_mock_task)

      described_class.any_instance.stubs(:exists?).returns(false)
    end
    let(:resource) { Puppet::Type.type(:scheduled_task).new(:name => 'Test Task', :command => 'C:\Windows\System32\notepad.exe') }

    it 'should clear the cached task object' do
      resource.provider.task.should == @mock_task
      resource.provider.task.should == @mock_task

      resource.provider.clear_task

      resource.provider.task.should == @new_mock_task
    end

    it 'should clear the cached list of triggers for the task' do
      @mock_task.stubs(:trigger_count).returns(1)
      @mock_task.stubs(:trigger).with(0).returns({
        'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE,
        'start_year'   => 2011,
        'start_month'  => 10,
        'start_day'    => 13,
        'start_hour'   => 14,
        'start_minute' => 21,
        'flags'        => 0,
      })
      @new_mock_task.stubs(:trigger_count).returns(1)
      @new_mock_task.stubs(:trigger).with(0).returns({
        'trigger_type' => Win32::TaskScheduler::TASK_TIME_TRIGGER_ONCE,
        'start_year'   => 2012,
        'start_month'  => 11,
        'start_day'    => 14,
        'start_hour'   => 15,
        'start_minute' => 22,
        'flags'        => 0,
      })

      mock_task_trigger = {
        'start_date' => '2011-10-13',
        'start_time' => '14:21',
        'schedule'   => 'once',
        'enabled'    => true,
        'index'      => 0,
      }

      resource.provider.trigger.should == mock_task_trigger
      resource.provider.trigger.should == mock_task_trigger

      resource.provider.clear_task

      resource.provider.trigger.should == {
        'start_date' => '2012-11-14',
        'start_time' => '15:22',
        'schedule'   => 'once',
        'enabled'    => true,
        'index'      => 0,
      }
    end
  end

  describe '.instances' do
    it 'should use the list of .job files to construct the list of scheduled_tasks' do
      job_files = ['foo.job', 'bar.job', 'baz.job']
      Win32::TaskScheduler.any_instance.stubs(:tasks).returns(job_files)
      job_files.each do |job|
        job = File.basename(job, '.job')

        described_class.expects(:new).with(:provider => :win32_taskscheduler, :name => job)
      end

      described_class.instances
    end
  end

  describe '#user_insync?', :if => Puppet.features.microsoft_windows? do
    let(:resource) { described_class.new(:name => 'foobar', :command => 'C:\Windows\System32\notepad.exe') }

    it 'should consider the user as in sync if the name matches' do
      Puppet::Util::Windows::Security.expects(:name_to_sid).with('joe').twice.returns('SID A')

      resource.should be_user_insync('joe', ['joe'])
    end

    it 'should consider the user as in sync if the current user is fully qualified' do
      Puppet::Util::Windows::Security.expects(:name_to_sid).with('joe').returns('SID A')
      Puppet::Util::Windows::Security.expects(:name_to_sid).with('MACHINE\joe').returns('SID A')

      resource.should be_user_insync('MACHINE\joe', ['joe'])
    end

    it 'should consider a current user of the empty string to be the same as the system user' do
      Puppet::Util::Windows::Security.expects(:name_to_sid).with('system').twice.returns('SYSTEM SID')

      resource.should be_user_insync('', ['system'])
    end

    it 'should consider different users as being different' do
      Puppet::Util::Windows::Security.expects(:name_to_sid).with('joe').returns('SID A')
      Puppet::Util::Windows::Security.expects(:name_to_sid).with('bob').returns('SID B')

      resource.should_not be_user_insync('joe', ['bob'])
    end
  end

  describe '#trigger_insync?' do
    let(:resource) { described_class.new(:name => 'foobar', :command => 'C:\Windows\System32\notepad.exe') }

    it 'should not consider any extra current triggers as in sync' do
      current = [
        {'start_date' => '2011-09-12', 'start_time' => '15:15', 'schedule' => 'once'},
        {'start_date' => '2012-10-13', 'start_time' => '16:16', 'schedule' => 'once'}
      ]
      desired = {'start_date' => '2011-09-12', 'start_time' => '15:15', 'schedule' => 'once'}

      resource.should_not be_trigger_insync(current, desired)
    end

    it 'should not consider any extra desired triggers as in sync' do
      current = {'start_date' => '2011-09-12', 'start_time' => '15:15', 'schedule' => 'once'}
      desired = [
        {'start_date' => '2011-09-12', 'start_time' => '15:15', 'schedule' => 'once'},
        {'start_date' => '2012-10-13', 'start_time' => '16:16', 'schedule' => 'once'}
      ]

      resource.should_not be_trigger_insync(current, desired)
    end

    it 'should consider triggers to be in sync if the sets of current and desired triggers are equal' do
      current = [
        {'start_date' => '2011-09-12', 'start_time' => '15:15', 'schedule' => 'once'},
        {'start_date' => '2012-10-13', 'start_time' => '16:16', 'schedule' => 'once'}
      ]
      desired = [
        {'start_date' => '2011-09-12', 'start_time' => '15:15', 'schedule' => 'once'},
        {'start_date' => '2012-10-13', 'start_time' => '16:16', 'schedule' => 'once'}
      ]

      resource.should be_trigger_insync(current, desired)
    end
  end

  describe '#triggers_same?' do
    let(:provider) { described_class.new(:name => 'foobar', :command => 'C:\Windows\System32\notepad.exe') }

    it "should not consider a disabled 'current' trigger to be the same" do
      current = {'schedule' => 'once', 'enabled' => false}
      desired = {'schedule' => 'once'}

      provider.should_not be_triggers_same(current, desired)
    end

    it 'should not consider triggers with different schedules to be the same' do
      current = {'schedule' => 'once'}
      desired = {'schedule' => 'weekly'}

      provider.should_not be_triggers_same(current, desired)
    end

    describe 'comparing daily triggers' do
      it "should consider 'desired' triggers not specifying 'every' to have the same value as the 'current' trigger" do
        current = {'schedule' => 'daily', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3}
        desired = {'schedule' => 'daily', 'start_date' => '2011-09-12', 'start_time' => '15:30'}

        provider.should be_triggers_same(current, desired)
      end

      it "should consider different 'start_dates' as different triggers" do
        current = {'schedule' => 'daily', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3}
        desired = {'schedule' => 'daily', 'start_date' => '2012-09-12', 'start_time' => '15:30', 'every' => 3}

        provider.should_not be_triggers_same(current, desired)
      end

      it "should consider different 'start_times' as different triggers" do
        current = {'schedule' => 'daily', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3}
        desired = {'schedule' => 'daily', 'start_date' => '2011-09-12', 'start_time' => '15:31', 'every' => 3}

        provider.should_not be_triggers_same(current, desired)
      end

      it 'should not consider differences in date formatting to be different triggers' do
        current = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3}
        desired = {'schedule' => 'weekly', 'start_date' => '2011-9-12',  'start_time' => '15:30', 'every' => 3}

        provider.should be_triggers_same(current, desired)
      end

      it 'should not consider differences in time formatting to be different triggers' do
        current = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '5:30',  'every' => 3}
        desired = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '05:30', 'every' => 3}

        provider.should be_triggers_same(current, desired)
      end

      it "should consider different 'every' as different triggers" do
        current = {'schedule' => 'daily', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3}
        desired = {'schedule' => 'daily', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 1}

        provider.should_not be_triggers_same(current, desired)
      end

      it 'should consider triggers that are the same as being the same' do
        trigger = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '01:30', 'every' => 1}

        provider.should be_triggers_same(trigger, trigger)
      end
    end

    describe 'comparing one-time triggers' do
      it "should consider different 'start_dates' as different triggers" do
        current = {'schedule' => 'daily', 'start_date' => '2011-09-12', 'start_time' => '15:30'}
        desired = {'schedule' => 'daily', 'start_date' => '2012-09-12', 'start_time' => '15:30'}

        provider.should_not be_triggers_same(current, desired)
      end

      it "should consider different 'start_times' as different triggers" do
        current = {'schedule' => 'daily', 'start_date' => '2011-09-12', 'start_time' => '15:30'}
        desired = {'schedule' => 'daily', 'start_date' => '2011-09-12', 'start_time' => '15:31'}

        provider.should_not be_triggers_same(current, desired)
      end

      it 'should not consider differences in date formatting to be different triggers' do
        current = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30'}
        desired = {'schedule' => 'weekly', 'start_date' => '2011-9-12',  'start_time' => '15:30'}

        provider.should be_triggers_same(current, desired)
      end

      it 'should not consider differences in time formatting to be different triggers' do
        current = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '1:30'}
        desired = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '01:30'}

        provider.should be_triggers_same(current, desired)
      end

      it 'should consider triggers that are the same as being the same' do
        trigger = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '01:30'}

        provider.should be_triggers_same(trigger, trigger)
      end
    end

    describe 'comparing monthly date-based triggers' do
      it "should consider 'desired' triggers not specifying 'months' to have the same value as the 'current' trigger" do
        current = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'months' => [3], 'on' => [1,'last']}
        desired = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'on' => [1, 'last']}

        provider.should be_triggers_same(current, desired)
      end

      it "should consider different 'start_dates' as different triggers" do
        current = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'months' => [1, 2], 'on' => [1, 3, 5, 7]}
        desired = {'schedule' => 'monthly', 'start_date' => '2011-10-12', 'start_time' => '15:30', 'months' => [1, 2], 'on' => [1, 3, 5, 7]}

        provider.should_not be_triggers_same(current, desired)
      end

      it "should consider different 'start_times' as different triggers" do
        current = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'months' => [1, 2], 'on' => [1, 3, 5, 7]}
        desired = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '22:30', 'months' => [1, 2], 'on' => [1, 3, 5, 7]}

        provider.should_not be_triggers_same(current, desired)
      end

      it 'should not consider differences in date formatting to be different triggers' do
        current = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'months' => [1, 2], 'on' => [1, 3, 5, 7]}
        desired = {'schedule' => 'monthly', 'start_date' => '2011-9-12',  'start_time' => '15:30', 'months' => [1, 2], 'on' => [1, 3, 5, 7]}

        provider.should be_triggers_same(current, desired)
      end

      it 'should not consider differences in time formatting to be different triggers' do
        current = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '5:30',  'months' => [1, 2], 'on' => [1, 3, 5, 7]}
        desired = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '05:30', 'months' => [1, 2], 'on' => [1, 3, 5, 7]}

        provider.should be_triggers_same(current, desired)
      end

      it "should consider different 'months' as different triggers" do
        current = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'months' => [1, 2], 'on' => [1, 3, 5, 7]}
        desired = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'months' => [1],    'on' => [1, 3, 5, 7]}

        provider.should_not be_triggers_same(current, desired)
      end

      it "should consider different 'on' as different triggers" do
        current = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'months' => [1, 2], 'on' => [1, 3, 5, 7]}
        desired = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'months' => [1, 2], 'on' => [1, 5, 7]}

        provider.should_not be_triggers_same(current, desired)
      end

      it 'should consider triggers that are the same as being the same' do
        trigger = {'schedule' => 'monthly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'months' => [1, 2], 'on' => [1, 3, 5, 7]}

        provider.should be_triggers_same(trigger, trigger)
      end
    end

    describe 'comparing monthly day-of-week-based triggers' do
      it "should consider 'desired' triggers not specifying 'months' to have the same value as the 'current' trigger" do
        current = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '15:30',
          'months'           => [3],
          'which_occurrence' => 'first',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }
        desired = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '15:30',
          'which_occurrence' => 'first',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }

        provider.should be_triggers_same(current, desired)
      end

      it "should consider different 'start_dates' as different triggers" do
        current = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '15:30',
          'months'           => [3],
          'which_occurrence' => 'first',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }
        desired = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-10-12',
          'start_time'       => '15:30',
          'months'           => [3],
          'which_occurrence' => 'first',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }

        provider.should_not be_triggers_same(current, desired)
      end

      it "should consider different 'start_times' as different triggers" do
        current = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '15:30',
          'months'           => [3],
          'which_occurrence' => 'first',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }
        desired = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '22:30',
          'months'           => [3],
          'which_occurrence' => 'first',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }

        provider.should_not be_triggers_same(current, desired)
      end

      it "should consider different 'months' as different triggers" do
        current = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '15:30',
          'months'           => [3],
          'which_occurrence' => 'first',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }
        desired = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '15:30',
          'months'           => [3, 5, 7, 9],
          'which_occurrence' => 'first',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }

        provider.should_not be_triggers_same(current, desired)
      end

      it "should consider different 'which_occurrence' as different triggers" do
        current = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '15:30',
          'months'           => [3],
          'which_occurrence' => 'first',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }
        desired = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '15:30',
          'months'           => [3],
          'which_occurrence' => 'last',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }

        provider.should_not be_triggers_same(current, desired)
      end

      it "should consider different 'day_of_week' as different triggers" do
        current = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '15:30',
          'months'           => [3],
          'which_occurrence' => 'first',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }
        desired = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '15:30',
          'months'           => [3],
          'which_occurrence' => 'first',
          'day_of_week'      => ['fri']
        }

        provider.should_not be_triggers_same(current, desired)
      end

      it 'should consider triggers that are the same as being the same' do
        trigger = {
          'schedule'         => 'monthly',
          'start_date'       => '2011-09-12',
          'start_time'       => '15:30',
          'months'           => [3],
          'which_occurrence' => 'first',
          'day_of_week'      => ['mon', 'tues', 'sat']
        }

        provider.should be_triggers_same(trigger, trigger)
      end
    end

    describe 'comparing weekly triggers' do
      it "should consider 'desired' triggers not specifying 'day_of_week' to have the same value as the 'current' trigger" do
        current = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}
        desired = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3}

        provider.should be_triggers_same(current, desired)
      end

      it "should consider different 'start_dates' as different triggers" do
        current = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}
        desired = {'schedule' => 'weekly', 'start_date' => '2011-10-12', 'start_time' => '15:30', 'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}

        provider.should_not be_triggers_same(current, desired)
      end

      it "should consider different 'start_times' as different triggers" do
        current = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}
        desired = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '22:30', 'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}

        provider.should_not be_triggers_same(current, desired)
      end

      it 'should not consider differences in date formatting to be different triggers' do
        current = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}
        desired = {'schedule' => 'weekly', 'start_date' => '2011-9-12',  'start_time' => '15:30', 'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}

        provider.should be_triggers_same(current, desired)
      end

      it 'should not consider differences in time formatting to be different triggers' do
        current = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '1:30',  'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}
        desired = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '01:30', 'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}

        provider.should be_triggers_same(current, desired)
      end

      it "should consider different 'every' as different triggers" do
        current = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 1, 'day_of_week' => ['mon', 'wed', 'fri']}
        desired = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}

        provider.should_not be_triggers_same(current, desired)
      end

      it "should consider different 'day_of_week' as different triggers" do
        current = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}
        desired = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3, 'day_of_week' => ['fri']}

        provider.should_not be_triggers_same(current, desired)
      end

      it 'should consider triggers that are the same as being the same' do
        trigger = {'schedule' => 'weekly', 'start_date' => '2011-09-12', 'start_time' => '15:30', 'every' => 3, 'day_of_week' => ['mon', 'wed', 'fri']}

        provider.should be_triggers_same(trigger, trigger)
      end
    end
  end

  describe '#normalized_date' do
    it 'should format the date without leading zeros' do
      described_class.normalized_date('2011-01-01').should == '2011-1-1'
    end
  end

  describe '#normalized_time' do
    it 'should format the time as {24h}:{minutes}' do
      described_class.normalized_time('8:37 PM').should == '20:37'
    end
  end

  describe '#translate_hash_to_trigger' do
    before :each do
      @puppet_trigger = {
        'start_date' => '2011-1-1',
        'start_time' => '01:10'
      }
    end
    let(:provider) { described_class.new(:name => 'Test Task', :command => 'C:\Windows\System32\notepad.exe') }
    let(:trigger)  { provider.translate_hash_to_trigger(@puppet_trigger) }

    describe 'when given a one-time trigger' do
      before :each do
        @puppet_trigger['schedule'] = 'once'
      end

      it 'should set the trigger_type to Win32::TaskScheduler::ONCE' do
        trigger['trigger_type'].should == Win32::TaskScheduler::ONCE
      end

      it 'should not set a type' do
        trigger.should_not be_has_key('type')
      end

      it "should require 'start_date'" do
        @puppet_trigger.delete('start_date')

        expect { trigger }.to raise_error(
          Puppet::Error,
          /Must specify 'start_date' when defining a one-time trigger/
        )
      end

      it "should require 'start_time'" do
        @puppet_trigger.delete('start_time')

        expect { trigger }.to raise_error(
          Puppet::Error,
          /Must specify 'start_time' when defining a trigger/
        )
      end

      it_behaves_like "a trigger that handles start_date and start_time" do
        let(:trigger_hash) {{'schedule' => 'once' }}
      end
    end

    describe 'when given a daily trigger' do
      before :each do
        @puppet_trigger['schedule'] = 'daily'
      end

      it "should default 'every' to 1" do
        trigger['type']['days_interval'].should == 1
      end

      it "should use the specified value for 'every'" do
        @puppet_trigger['every'] = 5

        trigger['type']['days_interval'].should == 5
      end

      it "should default 'start_date' to 'today'" do
        @puppet_trigger.delete('start_date')
        today = Time.now

        trigger['start_year'].should == today.year
        trigger['start_month'].should == today.month
        trigger['start_day'].should == today.day
      end

      it_behaves_like "a trigger that handles start_date and start_time" do
        let(:trigger_hash) {{'schedule' => 'daily', 'every' => 1}}
      end
    end

    describe 'when given a weekly trigger' do
      before :each do
        @puppet_trigger['schedule'] = 'weekly'
      end

      it "should default 'every' to 1" do
        trigger['type']['weeks_interval'].should == 1
      end

      it "should use the specified value for 'every'" do
        @puppet_trigger['every'] = 4

        trigger['type']['weeks_interval'].should == 4
      end

      it "should default 'day_of_week' to be every day of the week" do
        trigger['type']['days_of_week'].should == Win32::TaskScheduler::MONDAY    |
                                                  Win32::TaskScheduler::TUESDAY   |
                                                  Win32::TaskScheduler::WEDNESDAY |
                                                  Win32::TaskScheduler::THURSDAY  |
                                                  Win32::TaskScheduler::FRIDAY    |
                                                  Win32::TaskScheduler::SATURDAY  |
                                                  Win32::TaskScheduler::SUNDAY
      end

      it "should use the specified value for 'day_of_week'" do
        @puppet_trigger['day_of_week'] = ['mon', 'wed', 'fri']

        trigger['type']['days_of_week'].should == Win32::TaskScheduler::MONDAY    |
                                                  Win32::TaskScheduler::WEDNESDAY |
                                                  Win32::TaskScheduler::FRIDAY
      end

      it "should default 'start_date' to 'today'" do
        @puppet_trigger.delete('start_date')
        today = Time.now

        trigger['start_year'].should == today.year
        trigger['start_month'].should == today.month
        trigger['start_day'].should == today.day
      end

      it_behaves_like "a trigger that handles start_date and start_time" do
        let(:trigger_hash) {{'schedule' => 'weekly', 'every' => 1, 'day_of_week' => 'mon'}}
      end
    end

    shared_examples_for 'a monthly schedule' do
      it "should default 'months' to be every month" do
        trigger['type']['months'].should == Win32::TaskScheduler::JANUARY   |
                                            Win32::TaskScheduler::FEBRUARY  |
                                            Win32::TaskScheduler::MARCH     |
                                            Win32::TaskScheduler::APRIL     |
                                            Win32::TaskScheduler::MAY       |
                                            Win32::TaskScheduler::JUNE      |
                                            Win32::TaskScheduler::JULY      |
                                            Win32::TaskScheduler::AUGUST    |
                                            Win32::TaskScheduler::SEPTEMBER |
                                            Win32::TaskScheduler::OCTOBER   |
                                            Win32::TaskScheduler::NOVEMBER  |
                                            Win32::TaskScheduler::DECEMBER
      end

      it "should use the specified value for 'months'" do
        @puppet_trigger['months'] = [2, 8]

        trigger['type']['months'].should == Win32::TaskScheduler::FEBRUARY  |
                                            Win32::TaskScheduler::AUGUST
      end
    end

    describe 'when given a monthly date-based trigger' do
      before :each do
        @puppet_trigger['schedule'] = 'monthly'
        @puppet_trigger['on']       = [7, 14]
      end

      it_behaves_like 'a monthly schedule'

      it "should not allow 'which_occurrence' to be specified" do
        @puppet_trigger['which_occurrence'] = 'first'

        expect {trigger}.to raise_error(
          Puppet::Error,
          /Neither 'day_of_week' nor 'which_occurrence' can be specified when creating a monthly date-based trigger/
        )
      end

      it "should not allow 'day_of_week' to be specified" do
        @puppet_trigger['day_of_week'] = 'mon'

        expect {trigger}.to raise_error(
          Puppet::Error,
          /Neither 'day_of_week' nor 'which_occurrence' can be specified when creating a monthly date-based trigger/
        )
      end

      it "should require 'on'" do
        @puppet_trigger.delete('on')

        expect {trigger}.to raise_error(
          Puppet::Error,
          /Don't know how to create a 'monthly' schedule with the options: schedule, start_date, start_time/
        )
      end

      it "should default 'start_date' to 'today'" do
        @puppet_trigger.delete('start_date')
        today = Time.now

        trigger['start_year'].should == today.year
        trigger['start_month'].should == today.month
        trigger['start_day'].should == today.day
      end

      it_behaves_like "a trigger that handles start_date and start_time" do
        let(:trigger_hash) {{'schedule' => 'monthly', 'months' => 1, 'on' => 1}}
      end
    end

    describe 'when given a monthly day-of-week-based trigger' do
      before :each do
        @puppet_trigger['schedule']         = 'monthly'
        @puppet_trigger['which_occurrence'] = 'first'
        @puppet_trigger['day_of_week']      = 'mon'
      end

      it_behaves_like 'a monthly schedule'

      it "should not allow 'on' to be specified" do
        @puppet_trigger['on'] = 15

        expect {trigger}.to raise_error(
          Puppet::Error,
          /Neither 'day_of_week' nor 'which_occurrence' can be specified when creating a monthly date-based trigger/
        )
      end

      it "should require 'which_occurrence'" do
        @puppet_trigger.delete('which_occurrence')

        expect {trigger}.to raise_error(
          Puppet::Error,
          /which_occurrence must be specified when creating a monthly day-of-week based trigger/
        )
      end

      it "should require 'day_of_week'" do
        @puppet_trigger.delete('day_of_week')

        expect {trigger}.to raise_error(
          Puppet::Error,
          /day_of_week must be specified when creating a monthly day-of-week based trigger/
        )
      end

      it "should default 'start_date' to 'today'" do
        @puppet_trigger.delete('start_date')
        today = Time.now

        trigger['start_year'].should == today.year
        trigger['start_month'].should == today.month
        trigger['start_day'].should == today.day
      end

      it_behaves_like "a trigger that handles start_date and start_time" do
        let(:trigger_hash) {{'schedule' => 'monthly', 'months' => 1, 'which_occurrence' => 'first', 'day_of_week' => 'mon'}}
      end
    end
  end

  describe '#validate_trigger' do
    let(:provider) { described_class.new(:name => 'Test Task', :command => 'C:\Windows\System32\notepad.exe') }

    it 'should succeed if all passed triggers translate from hashes to triggers' do
      triggers_to_validate = [
        {'schedule' => 'once',   'start_date' => '2011-09-13', 'start_time' => '13:50'},
        {'schedule' => 'weekly', 'start_date' => '2011-09-13', 'start_time' => '13:50', 'day_of_week' => 'mon'}
      ]

      provider.validate_trigger(triggers_to_validate).should == true
    end

    it 'should use the exception from translate_hash_to_trigger when it fails' do
      triggers_to_validate = [
        {'schedule' => 'once', 'start_date' => '2011-09-13', 'start_time' => '13:50'},
        {'schedule' => 'monthly', 'this is invalid' => true}
      ]

      expect {provider.validate_trigger(triggers_to_validate)}.to raise_error(
        Puppet::Error,
        /#{Regexp.escape("Unknown trigger option(s): ['this is invalid']")}/
      )
    end
  end

  describe '#flush' do
    let(:resource) do
      Puppet::Type.type(:scheduled_task).new(
        :name    => 'Test Task',
        :command => 'C:\Windows\System32\notepad.exe',
        :ensure  => @ensure
      )
    end

    before :each do
      @mock_task = mock
      @mock_task.responds_like(Win32::TaskScheduler.new)
      @mock_task.stubs(:exists?).returns(true)
      @mock_task.stubs(:activate)
      Win32::TaskScheduler.stubs(:new).returns(@mock_task)

      @command = 'C:\Windows\System32\notepad.exe'
    end

    describe 'when :ensure is :present' do
      before :each do
        @ensure = :present
      end

      it 'should save the task' do
        @mock_task.expects(:save)

        resource.provider.flush
      end

      it 'should fail if the command is not specified' do
        resource = Puppet::Type.type(:scheduled_task).new(
          :name    => 'Test Task',
          :ensure  => @ensure
        )

        expect { resource.provider.flush }.to raise_error(
          Puppet::Error,
          'Parameter command is required.'
        )
      end
    end

    describe 'when :ensure is :absent' do
      before :each do
        @ensure = :absent
        @mock_task.stubs(:activate)
      end

      it 'should not save the task if :ensure is :absent' do
        @mock_task.expects(:save).never

        resource.provider.flush
      end

      it 'should not fail if the command is not specified' do
        @mock_task.stubs(:save)

        resource = Puppet::Type.type(:scheduled_task).new(
          :name    => 'Test Task',
          :ensure  => @ensure
        )

        resource.provider.flush
      end
    end
  end

  describe 'property setter methods' do
    let(:resource) do
      Puppet::Type.type(:scheduled_task).new(
        :name    => 'Test Task',
        :command => 'C:\dummy_task.exe'
      )
    end

    before :each do
        @mock_task = mock
        @mock_task.responds_like(Win32::TaskScheduler.new)
        @mock_task.stubs(:exists?).returns(true)
        @mock_task.stubs(:activate)
        Win32::TaskScheduler.stubs(:new).returns(@mock_task)
    end

    describe '#command=' do
      it 'should set the application_name on the task' do
        @mock_task.expects(:application_name=).with('C:\Windows\System32\notepad.exe')

        resource.provider.command = 'C:\Windows\System32\notepad.exe'
      end
    end

    describe '#arguments=' do
      it 'should set the parameters on the task' do
        @mock_task.expects(:parameters=).with(['/some /arguments /here'])

        resource.provider.arguments = ['/some /arguments /here']
      end
    end

    describe '#working_dir=' do
      it 'should set the working_directory on the task' do
        @mock_task.expects(:working_directory=).with('C:\Windows\System32')

        resource.provider.working_dir = 'C:\Windows\System32'
      end
    end

    describe '#enabled=' do
      it 'should set the disabled flag if the task should be disabled' do
        @mock_task.stubs(:flags).returns(0)
        @mock_task.expects(:flags=).with(Win32::TaskScheduler::DISABLED)

        resource.provider.enabled = :false
      end

      it 'should clear the disabled flag if the task should be enabled' do
        @mock_task.stubs(:flags).returns(Win32::TaskScheduler::DISABLED)
        @mock_task.expects(:flags=).with(0)

        resource.provider.enabled = :true
      end
    end

    describe '#trigger=' do
      let(:resource) do
        Puppet::Type.type(:scheduled_task).new(
          :name    => 'Test Task',
          :command => 'C:\Windows\System32\notepad.exe',
          :trigger => @trigger
        )
      end

      before :each do
        @mock_task = mock
        @mock_task.responds_like(Win32::TaskScheduler.new)
        @mock_task.stubs(:exists?).returns(true)
        @mock_task.stubs(:activate)
        Win32::TaskScheduler.stubs(:new).returns(@mock_task)
      end

      it 'should not consider all duplicate current triggers in sync with a single desired trigger' do
        @trigger = {'schedule' => 'once', 'start_date' => '2011-09-15', 'start_time' => '15:10'}
        current_triggers = [
          {'schedule' => 'once', 'start_date' => '2011-09-15', 'start_time' => '15:10', 'index' => 0},
          {'schedule' => 'once', 'start_date' => '2011-09-15', 'start_time' => '15:10', 'index' => 1},
          {'schedule' => 'once', 'start_date' => '2011-09-15', 'start_time' => '15:10', 'index' => 2},
        ]
        resource.provider.stubs(:trigger).returns(current_triggers)
        @mock_task.expects(:delete_trigger).with(1)
        @mock_task.expects(:delete_trigger).with(2)

        resource.provider.trigger = @trigger
      end

      it 'should remove triggers not defined in the resource' do
        @trigger = {'schedule' => 'once', 'start_date' => '2011-09-15', 'start_time' => '15:10'}
        current_triggers = [
          {'schedule' => 'once', 'start_date' => '2011-09-15', 'start_time' => '15:10', 'index' => 0},
          {'schedule' => 'once', 'start_date' => '2012-09-15', 'start_time' => '15:10', 'index' => 1},
          {'schedule' => 'once', 'start_date' => '2013-09-15', 'start_time' => '15:10', 'index' => 2},
        ]
        resource.provider.stubs(:trigger).returns(current_triggers)
        @mock_task.expects(:delete_trigger).with(1)
        @mock_task.expects(:delete_trigger).with(2)

        resource.provider.trigger = @trigger
      end

      it 'should add triggers defined in the resource, but not found on the system' do
        @trigger = [
          {'schedule' => 'once', 'start_date' => '2011-09-15', 'start_time' => '15:10'},
          {'schedule' => 'once', 'start_date' => '2012-09-15', 'start_time' => '15:10'},
          {'schedule' => 'once', 'start_date' => '2013-09-15', 'start_time' => '15:10'},
        ]
        current_triggers = [
          {'schedule' => 'once', 'start_date' => '2011-09-15', 'start_time' => '15:10', 'index' => 0},
        ]
        resource.provider.stubs(:trigger).returns(current_triggers)
        @mock_task.expects(:trigger=).with(resource.provider.translate_hash_to_trigger(@trigger[1]))
        @mock_task.expects(:trigger=).with(resource.provider.translate_hash_to_trigger(@trigger[2]))

        resource.provider.trigger = @trigger
      end
    end

    describe '#user=', :if => Puppet.features.microsoft_windows? do
      before :each do
        @mock_task = mock
        @mock_task.responds_like(Win32::TaskScheduler.new)
        @mock_task.stubs(:exists?).returns(true)
        @mock_task.stubs(:activate)
        Win32::TaskScheduler.stubs(:new).returns(@mock_task)
      end

      it 'should use nil for user and password when setting the user to the SYSTEM account' do
        Puppet::Util::Windows::Security.stubs(:name_to_sid).with('system').returns('SYSTEM SID')

        resource = Puppet::Type.type(:scheduled_task).new(
          :name    => 'Test Task',
          :command => 'C:\dummy_task.exe',
          :user    => 'system'
        )

        @mock_task.expects(:set_account_information).with(nil, nil)

        resource.provider.user = 'system'
      end

      it 'should use the specified user and password when setting the user to anything other than SYSTEM' do
        Puppet::Util::Windows::Security.stubs(:name_to_sid).with('my_user_name').returns('SID A')

        resource = Puppet::Type.type(:scheduled_task).new(
          :name     => 'Test Task',
          :command  => 'C:\dummy_task.exe',
          :user     => 'my_user_name',
          :password => 'my password'
        )

        @mock_task.expects(:set_account_information).with('my_user_name', 'my password')

        resource.provider.user = 'my_user_name'
      end
    end
  end

  describe '#create' do
    let(:resource) do
      Puppet::Type.type(:scheduled_task).new(
        :name        => 'Test Task',
        :enabled     => @enabled,
        :command     => @command,
        :arguments   => @arguments,
        :working_dir => @working_dir,
        :trigger     => { 'schedule' => 'once', 'start_date' => '2011-09-27', 'start_time' => '17:00' }
      )
    end

    before :each do
      @enabled     = :true
      @command     = 'C:\Windows\System32\notepad.exe'
      @arguments   = '/a /list /of /arguments'
      @working_dir = 'C:\Windows\Some\Directory'

      @mock_task = mock
      @mock_task.responds_like(Win32::TaskScheduler.new)
      @mock_task.stubs(:exists?).returns(true)
      @mock_task.stubs(:activate)
      @mock_task.stubs(:application_name=)
      @mock_task.stubs(:parameters=)
      @mock_task.stubs(:working_directory=)
      @mock_task.stubs(:set_account_information)
      @mock_task.stubs(:flags)
      @mock_task.stubs(:flags=)
      @mock_task.stubs(:trigger_count).returns(0)
      @mock_task.stubs(:trigger=)
      @mock_task.stubs(:save)
      Win32::TaskScheduler.stubs(:new).returns(@mock_task)

      described_class.any_instance.stubs(:sync_triggers)
    end

    it 'should set the command' do
      resource.provider.expects(:command=).with(@command)

      resource.provider.create
    end

    it 'should set the arguments' do
      resource.provider.expects(:arguments=).with(@arguments)

      resource.provider.create
    end

    it 'should set the working_dir' do
      resource.provider.expects(:working_dir=).with(@working_dir)

      resource.provider.create
    end

    it "should set the user" do
      resource.provider.expects(:user=).with(:system)

      resource.provider.create
    end

    it 'should set the enabled property' do
      resource.provider.expects(:enabled=)

      resource.provider.create
    end

    it 'should sync triggers' do
      resource.provider.expects(:trigger=)

      resource.provider.create
    end
  end
end
