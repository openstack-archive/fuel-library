#!/usr/bin/env python

#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
"""
This tool can extract the useful lines from Astute and Puppet logs
within the Fuel log snapshot or on the live Fuel master node.

usage: fuel_logs [-h] [--astute] [--puppet] [--clear] [--sort] [--evals]
                 [--mcagent] [--less]
                 [SNAPSHOT [SNAPSHOT ...]]

positional arguments:
  SNAPSHOT       Take logs from these snapshots

optional arguments:
  -h, --help     show this help message and exit
  --astute, -a   Parse Astute log
  --puppet, -p   Parse Puppet logs
  --clear, -c    Clear the logs on the master node
  --sort, -s     Sort Puppet logs by date
  --evals, -e    Show Puppet evaltrace lines
  --mcagent, -m  Show Astute MCAgent calls debug
  --less, -l     Redirect data to the "less" pager

Using anywhere to view Fuel snapshot data:

fuel_logs.py fail_error_deploy_ha_vlan-2015_02_20__20_35_18.tar.gz

Using on the live Fuel Master node:

fuel_logs.py -a View the current Astute log
fuel_logs.py -p View the current Puppet logs

Using without -a and -p options assumes both options

fuel_logs.py -c Truncates Astute and Puppet logs. Respects -a and -p options.

It you are running and debugging many deployments on a single master node
you may want to truncate the logs from the previous deployments. Using -l
option is aslo recomended for interactive use.
"""

import tarfile
import sys
import os
import re
import argparse
from datetime import datetime


class IO(object):
    """
    This object does the input, the output and the main application logic
    """
    pipe = None
    args = None

    @classmethod
    def separator(cls):
        """
        Draw a separator line if both Puppet and Astute logs are enabled
        :return:
        """
        if cls.args.puppet and cls.args.astute:
            IO.output('#' * 80 + "\n")

    @classmethod
    def process_snapshots(cls):
        """
        Extract the logs from the snapshots and process the logs
        :return:
        """
        fuel_snapshot = FuelSnapshot()
        for snapshot in cls.args.snapshots:

            if not os.path.isfile(snapshot):
                continue

            fuel_snapshot.open_fuel_snapshot(snapshot)

            if cls.args.astute:
                fuel_snapshot.parse_astute_log(show_mcagent=cls.args.mcagent)

            cls.separator()

            if cls.args.puppet:
                fuel_snapshot.parse_puppet_logs(enable_sort=cls.args.sort,
                                                show_evals=cls.args.evals)

            fuel_snapshot.close_fuel_snapshot()

    @classmethod
    def process_logs(cls):
        """
        Read the logs from the live Fuel master system and process them
        :return:
        """
        fuel_logs = FuelLogs()
        if cls.args.astute:
            if cls.args.clear:
                fuel_logs.clear_astute_logs()
            else:
                fuel_logs.parse_astute_logs(show_mcagent=cls.args.mcagent)

        cls.separator()

        if cls.args.puppet:
            if cls.args.clear:
                fuel_logs.clear_puppet_logs()
            else:
                fuel_logs.parse_puppet_logs(enable_sort=cls.args.sort,
                                            show_evals=cls.args.evals)

    @classmethod
    def main(cls):
        """
        The main application workflow
        :return:
        """
        cls.options()

        if cls.args.less:
            cls.open_pager()

        if len(cls.args.snapshots) == 0:
            cls.process_logs()
        else:
            cls.process_snapshots()

        if cls.args.less:
            cls.close_pager()

    @classmethod
    def open_pager(cls):
        """
        Open the pipe to the pager subprocess in oreder
        to display the output there
        :return:
        """
        cls.pipe = os.popen('less --chop-long-lines', 'w')

    @classmethod
    def close_pager(cls):
        """
        Close the pager process and finish the output
        :return:
        """
        cls.pipe.close()
        cls.pipe = None

    @classmethod
    def output(cls, line):
        """
        Output a single line of text to the console
        or to the pager
        :param line: the line to display
        :type line: str
        :return:
        """
        if line[-1] != '\n':
            line += '\n'
        if not cls.pipe:
            sys.stdout.write(line)
        else:
            cls.pipe.write(line)

    @classmethod
    def options(cls):
        """
        Parse the input options and parameters
        :return: arguments structure
        """
        parser = argparse.ArgumentParser()
        parser.add_argument("--astute", "-a",
                            action="store_true",
                            default=False,
                            help='Parse Astute log')
        parser.add_argument("--puppet", "-p",
                            action="store_true",
                            default=False,
                            help='Parse Puppet logs')
        parser.add_argument("--clear", "-c",
                            action="store_true",
                            default=False,
                            help='Clear the logs on the master node')
        parser.add_argument("--sort", "-s",
                            action="store_true",
                            default=False,
                            help='Sort Puppet logs by date')
        parser.add_argument("--evals", "-e",
                            action="store_true",
                            default=False,
                            help='Show Puppet evaltrace lines')
        parser.add_argument("--mcagent", "-m",
                            action="store_true",
                            default=False,
                            help='Show Astute MCAgent calls debug')
        parser.add_argument("--less", "-l",
                            action="store_true",
                            default=False,
                            help='Redirect data to the "less" pager')
        parser.add_argument('snapshots',
                            metavar='SNAPSHOT',
                            type=str,
                            nargs='*',
                            default=[],
                            help='Take logs from these snapshots')
        cls.args = parser.parse_args()
        if not cls.args.puppet and not cls.args.astute:
            cls.args.puppet = True
            cls.args.astute = True
        return cls.args


class AstuteLog(object):
    """
    This class is responsible for Astute log parsing
    """
    def __init__(self):
        self.content = []
        self.log = []
        self.show_mcagent = False

    def set_show_mcagent(self, show_mcagent):
        """
        Set if we want to show extensive MCAgent debug
        :param show_mcagent: enable or disable MCAgent
        :type show_mcagent: bool
        :return:
        """
        self.show_mcagent = show_mcagent

    def parse(self, content):
        """
        Parse the string containing the log content
        :param content: the log file content
        :type content: str
        :return:
        """
        self.content = content.splitlines()
        for record in self.each_record():
            self.rpc_call(record)
            self.rpc_cast(record)
            self.task_status(record)
            self.task_run(record)
            self.hook_run(record)
            if self.show_mcagent:
                self.cmd_exec(record)
                self.mc_agent_results(record)

    def output(self):
        """
        Output the parsed log content
        :return:
        """
        for line in self.log:
            IO.output(line)

    def clear(self):
        """
        Clear the parsed and raw log contents
        :return:
        """
        self.log = []
        self.content = []

    def add_line(self, record):
        """
        Add a line from the input log to the parsed log
        :param record: the line to add
        :type record: str
        :return:
        """
        record = record.replace('\n', ' ')
        record = record.replace('\\n', ' ')
        record = ' '.join(record.split())
        if record[-1] != '\n':
            record += '\n'
        self.log.append(record)

    def each_record(self):
        """
        Iterates through the multiline records of the log file
        :return: iterator
        """
        record = ''
        date_regexp = re.compile(r'^\d+-\d+-\S+\s')
        for line in self.content:
            if re.match(date_regexp, line):
                yield record
                record = line
            else:
                record += line
        yield record

    def rpc_call(self, record):
        """
        Catch the lines with RPC calls from Nailgun to Astute
        :param record: log record
        :type record: str
        :return:
        """
        if 'Processing RPC call' in record:
            self.add_line(record)

    def rpc_cast(self, record):
        """
        Catch the lines with RPC casts from Astute to Nailgun
        :param record: log record
        :type record: str
        :return:
        """
        if 'Casting message to Nailgun' in record:
            if 'deploying' in record:
                return
            if 'provisioning' in record:
                return
            self.add_line(record)

    def task_status(self, record):
        """
        Catch the lines with modular task status reports
        :param record: log record
        :type record: str
        :return:
        """
        if 'Task' in record:
            if 'deploying' in record:
                return
            self.add_line(record)

    def task_run(self, record):
        """
        Catch the lines with modular task run debug structures
        :param record: log record
        :type record: str
        :return:
        """
        if 'run task' in record:
            self.add_line(record)

    def hook_run(self, record):
        """
        Catch the lines with Astute pre/post deploy hooks debug structures
        :param record: log record
        :type record: str
        :return:
        """
        if 'Run hook' in record:
            self.add_line(record)

    def cmd_exec(self, record):
        """
        Catch the lines with cmd execution debug reports
        :param record: log record
        :type record: str
        :return:
        """
        if 'cmd:' in record and 'stdout:' in record and 'stderr:' in record:
            self.add_line(record)

    def mc_agent_results(self, record):
        """
        Catch the lines with MCAgent call traces
        :param record: log record
        :type record: str
        :return:
        """
        if 'MC agent' in record and 'results:' in record:
            if 'puppetd' in record:
                return
            self.add_line(record)


class PuppetLog(object):
    """
    This class is responible for Puppet log parsing
    """
    def __init__(self):
        self.content = []
        self.log = []
        self.log_name = None
        self.show_evals = False
        self.enable_sort = False

    def set_log_name(self, log_name):
        """
        Set the puppet log name
        :param log_name: log name
        :type log_name: str
        :return:
        """
        self.log_name = log_name

    def set_show_evals(self, show_evals):
        """
        Enable or disable show of Puppet evaltrace lines
        :param show_evals: evaltrace enable
        :type show_evals: bool
        :return:
        """
        self.show_evals = show_evals

    def set_enable_sort(self, enable_sort):
        """
        Enable or disable sorting log lines by event time
        instead of sorting by node
        :param enable_sort: sort by date
        :type enable_sort: bool
        :return:
        """
        self.enable_sort = enable_sort

    def parse(self, content):
        """
        Parse the sting with Puppet log content
        :param content: Puppet log
        :type content: str
        :return:
        """
        self.content = content.splitlines()
        for line in self.content:
            self.err_line(line)
            self.catalog_start(line)
            self.catalog_end(line)
            self.catalog_modular(line)
            if self.show_evals:
                self.resource_evaluation(line)

    @staticmethod
    def node_name(string):
        """
        Extract the node name from the Puppet log name
        It is used to mark log lines in the output
        :param string: log name
        :type string: str
        :return: node name
        :rtype: str
        """
        match = re.search(r'(node-\d+)', string)
        if match:
            return match.group(0)

    def output(self):
        """
        Output the collected log lines sorting
        them if enabled
        :return:
        """
        if self.enable_sort:
            self.sort_log()
        for record in self.log:
            log = record.get('log', None)
            time = record.get('time', None)
            line = record.get('line', None)
            if not (log and time and line):
                continue
            IO.output("%s %s %s\n" % (self.node_name(log),
                                      time.isoformat(), line))

    def clear(self):
        """
        Clear both input and collected log lines
        :return:
        """
        self.log = []
        self.content = []

    def sort_log(self):
        """
        Sort the collected log lines bu the event date and time
        :return:
        """
        self.log = sorted(self.log,
                          key=lambda record: record.get('time', None))

    def convert_line(self, line):
        """
        Split the log line to date, log name and event string
        :param line: log line
        :type line: str
        :return: log record
        :rtype: dict
        """
        fields = line.split()
        time = fields[0]
        line = ' '.join(fields[1:])
        time = time[0:26]
        try:
            time = datetime.strptime(time, "%Y-%m-%dT%H:%M:%S.%f")
        except ValueError:
            return
        record = {
            'time': time,
            'line': line,
            'log': self.log_name,
        }
        return record

    def add_line(self, line):
        """
        Add a line from the input log to the
        collected log lines
        :param line: log line
        :type line: str
        :return:
        """
        record = self.convert_line(line)
        if record:
            self.log.append(record)

    def err_line(self, line):
        """
        Catch lines that are marked as 'err:'
        :param line: log line
        :type line: str
        :return:
        """
        if 'err:' in line:
            self.add_line(line)

    def catalog_end(self, line):
        """
        Catch the end of the catalog run
        :param line: log line
        :type line: str
        :return:
        """
        if 'Finished catalog run' in line:
            self.add_line(line)

    def catalog_start(self, line):
        """
        Catch the end of the catalog compilation and start of the catalog run
        :param line: log line
        :type line: str
        :return:
        """
        if 'Compiled catalog for' in line:
            self.add_line(line)

    def catalog_modular(self, line):
        """
        Catch the MODULAR marker of the modular tasks
        :param line: log line
        :type line: str
        :return:
        """
        if 'MODULAR' in line:
            self.add_line(line)

    def resource_evaluation(self, line):
        """
        Catch the evaltrace lines marking every resource
        processing start and end
        :param line: log line
        :type line: str
        :return:
        """
        if 'Starting to evaluate the resource' in line:
            self.add_line(line)
        if 'Evaluated in' in line:
            self.add_line(line)


class FuelSnapshot(object):
    """
    This class extracts data from the Fuel log snapshot
    """
    def __init__(self):
        self.snapshot = None

    def open_fuel_snapshot(self, snapshot):
        """
        Open the Fuel log snapshot file
        :param snapshot: path to file
        :type snapshot: str
        :return:
        """
        self.snapshot = tarfile.open(snapshot)

    def close_fuel_snapshot(self):
        """
        Close the Fuel log snapshot file
        :return:
        """
        if self.snapshot:
            self.snapshot.close()

    def astute_logs(self):
        """
        Find the Astute logs in the snapshot archive
        :return: iterator
        """
        for log in self.snapshot.getmembers():
            if not log.isfile():
                continue
            if log.name.endswith('/astute.log'):
                yield log

    def parse_astute_log(self, show_mcagent=False):
        """
        Parse the Astute log from the archive
        :param show_mcagent: show or hide MCAgent debug
        :type show_mcagent: bool
        :return:
        """
        astute_logs = AstuteLog()
        astute_logs.set_show_mcagent(show_mcagent)
        for astute_log in self.astute_logs():
            log = self.snapshot.extractfile(astute_log)
            content = log.read()
            astute_logs.parse(content)
        astute_logs.output()
        astute_logs.clear()

    def puppet_logs(self):
        """
        Find the Puppet logs inside the snapshot archive
        :return: iterator
        """
        for log in self.snapshot.getmembers():
            if not log.isfile():
                continue
            if log.name.endswith('/puppet-apply.log'):
                yield log

    def parse_puppet_logs(self, enable_sort=False, show_evals=False):
        """
        Parse the Puppet logs found inside the archive
        :param enable_sort: enable sorting of logs by date
        :type enable_sort: bool
        :param show_evals: show evaltrace lines in the logs
        :type show_evals: bool
        :return:
        """
        puppet_logs = PuppetLog()
        puppet_logs.set_show_evals(show_evals)
        puppet_logs.set_enable_sort(enable_sort)
        for puppet_log in self.puppet_logs():
            name = puppet_log.name
            log = self.snapshot.extractfile(puppet_log)
            content = log.read()
            puppet_logs.set_log_name(name)
            puppet_logs.parse(content)
        puppet_logs.output()
        puppet_logs.clear()


class FuelLogs(object):
    """
    This class works with Astute and Puppet logs on the
    live Fuel master system
    """
    def __init__(self, log_dir='/var/log'):
        self.log_dir = log_dir

    def puppet_logs(self):
        """
        Find the Puppet logs in the log directory
        :return: iterator
        """
        for root, files, files in os.walk(self.log_dir):
            for log_file in files:
                if log_file == 'puppet-apply.log':
                    path = os.path.join(root, log_file)
                    IO.output('Processing: %s' % path)
                    yield path

    def astute_logs(self):
        """
        Find the Astute logs in the log directory
        :return: iterator
        """
        for root, files, files in os.walk(self.log_dir):
            for log_file in files:
                if log_file == 'astute.log':
                    path = os.path.join(root, log_file)
                    IO.output('Processing: %s' % path)
                    yield path

    @staticmethod
    def clear_log(log_file):
        """
        Truncate the log in the log dir. It's better to
        truncate the logs between several deployment runs
        to drop all the previous lines.
        :param log_file: path to log file
        :type log_file: str
        :return:
        """
        if not os.path.isfile(log_file):
            return
        IO.output('Clear log: %s' % log_file)
        with open(log_file, 'w') as log:
            log.truncate()
            log.close()

    def parse_astute_logs(self, show_mcagent=False):
        """
        Parse Astute log on the Fuel master system
        :param show_mcagent: show MCAgent call debug
        :type show_mcagent: bool
        :return:
        """
        astute_logs = AstuteLog()
        astute_logs.set_show_mcagent(show_mcagent)
        for astute_log in self.astute_logs():
            with open(astute_log, 'r') as log:
                content = log.read()
                astute_logs.parse(content)
        astute_logs.output()
        astute_logs.clear()

    def parse_puppet_logs(self, enable_sort=False, show_evals=False):
        """
        Parse Puppet logs on the Fuel master system
        :param enable_sort: sort log files by date
        :type enable_sort: bool
        :param show_evals: show evaltrace lines
        :type show_evals: bool
        :return:
        """
        puppet_logs = PuppetLog()
        puppet_logs.set_show_evals(show_evals)
        puppet_logs.set_enable_sort(enable_sort)
        for puppet_log in self.puppet_logs():
            with open(puppet_log, 'r') as log:
                puppet_logs.set_log_name(puppet_log)
                content = log.read()
                puppet_logs.parse(content)
        puppet_logs.output()
        puppet_logs.clear()

    def clear_astute_logs(self):
        """
        Clear all Astute logs found in the log dir
        :return:
        """
        for astute_log in self.astute_logs():
            self.clear_log(astute_log)

    def clear_puppet_logs(self):
        """
        Clear all Puppet logs found in the log dir
        :return:
        """
        for puppet_log in self.puppet_logs():
            self.clear_log(puppet_log)

##############################################################################

if __name__ == '__main__':
    IO.main()
