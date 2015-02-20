#!/usr/bin/env python
import tarfile
import sys
import os
import re
import argparse
from datetime import datetime


class IO:
    pipe = None

    @classmethod
    def open_pager(cls):
        cls.pipe = os.popen('less --chop-long-lines', 'w')

    @classmethod
    def close_pager(cls):
        cls.pipe.close()
        cls.pipe = None

    @classmethod
    def output(cls, line):
        if line[-1] != "\n":
            line += "\n"
        if not cls.pipe:
            sys.stdout.write(line)
        else:
            cls.pipe.write(line)


class AstuteLog:
    def __init__(self):
        self.log = []

    def parse(self, content):
        if type(content) == file:
            content = content.read()
        if type(content) == str:
            content = content.splitlines()
        for record in self.each_record(content):
            self.rpc_call(record)
            self.rpc_cast(record)
            self.task_status(record)
            self.task_run(record)
            self.hook_run(record)
            self.cmd_exec(record)
            #self.mc_agent_results(record)

    def output(self):
        for line in self.log:
            IO.output(line)

    def clear(self):
        self.log = []

    def add_line(self, record):
        record = record.replace("\n", ' ')
        record = record.replace('\\n', ' ')
        record = ' '.join(record.split())
        if record[-1] != "\n":
            record += "\n"
        self.log.append(record)

    def each_record(self, content):
        record = ''
        date_regexp = re.compile('^\d+-\d+-\S+\s')
        for line in content:
            if re.match(date_regexp, line):
                yield record
                record = line
            else:
                record += line
        yield record

    def rpc_call(self, record):
        if 'Processing RPC call' in record:
            self.add_line(record)

    def rpc_cast(self, record):
        if 'Casting message to Nailgun' in record:
            if 'deploying' in record:
                return
            if 'provisioning' in record:
                return
            self.add_line(record)

    def task_status(self, record):
        if 'Task' in record:
            if 'deploying' in record:
                return
            self.add_line(record)

    def task_run(self, record):
        if 'run task' in record:
            self.add_line(record)

    def hook_run(self, record):
        if 'Run hook' in record:
            self.add_line(record)

    def cmd_exec(self, record):
        if 'cmd:' in record and 'stdout:' in record and 'stderr:' in record:
            self.add_line(record)

    def mc_agent_results(self, record):
        if 'MC agent' in record and 'results:' in record:
            if 'puppetd' in record:
                return
            self.add_line(record)


class PuppetLog:
    def __init__(self):
        self.log = []
        self.log_name = None
        self.show_evals = False
        self.enable_sort = False

    def set_log_name(self, log_name):
        self.log_name = log_name

    def set_show_evals(self, show_evals):
        self.show_evals = show_evals

    def set_enable_sort(self, enable_sort):
        self.enable_sort = enable_sort

    def parse(self, content):
        if type(content) == file:
            content = content.read()
        if type(content) == str:
            content = content.splitlines()
        for line in content:
            self.err_line(line)
            self.catalog_start(line)
            self.catalog_end(line)
            self.catalog_modular(line)
            if self.show_evals:
                self.resource_evaluation(line)

    def node_name(self, string):
        m = re.search('(node-\d+)', string)
        if m:
            return m.group(0)

    def output(self):
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
        self.log = []

    def sort_log(self):
        self.log = sorted(self.log,
                          key=lambda record: record.get('time', None))

    def convert_line(self, line):
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
        record = self.convert_line(line)
        if record:
            self.log.append(record)

    def err_line(self, line):
        if 'err:' in line:
            self.add_line(line)

    def catalog_end(self, line):
        if 'Finished catalog run' in line:
            self.add_line(line)

    def catalog_start(self, line):
        if 'Compiled catalog for' in line:
            self.add_line(line)

    def catalog_modular(self, line):
        if 'MODULAR' in line:
            self.add_line(line)

    def resource_evaluation(self, line):
        if 'Starting to evaluate the resource' in line:
            self.add_line(line)
        if 'Evaluated in' in line:
            self.add_line(line)


class FuelSnapshot:
    def __init__(self):
        self._snapshot = None

    @property
    def snapshot(self):
        return self._snapshot

    def open_fuel_snapshot(self, snapshot):
        self._snapshot = tarfile.open(snapshot)

    def close_fuel_snapshot(self):
        if self.snapshot:
            self.snapshot.close()

    def astute_log(self):
        for log in self.snapshot.getmembers():
            if not log.isfile():
                continue
            if log.name.endswith('/astute.log'):
                return log

    def parse_astute_log(self):
        astute_log = self.astute_log()
        if not astute_log:
            return
        log = self.snapshot.extractfile(astute_log)
        al = AstuteLog()
        al.parse(log)
        al.output()

    def puppet_logs(self):
        for log in self.snapshot.getmembers():
            if not log.isfile():
                continue
            if log.name.endswith('/puppet-apply.log'):
                yield log

    def parse_puppet_logs(self, enable_sort=False, show_evals=False):
        pl = PuppetLog()
        pl.set_show_evals(show_evals)
        pl.set_enable_sort(enable_sort)
        for log in self.puppet_logs():
            name = log.name
            content = self.snapshot.extractfile(log)
            pl.set_log_name(name)
            pl.parse(content)
        pl.output()
        pl.clear()


class FuelLogs:
    def __init__(self, log_dir='/var/log'):
        self.log_dir = log_dir

    def puppet_logs(self):
        for root, dirs, files in os.walk(self.log_dir):
            for file in files:
                if file == 'puppet-apply.log':
                    path = os.path.join(root, file)
                    print 'Processing: %s' % path
                    yield path

    def astute_logs(self):
        for root, dirs, files in os.walk('/var/log'):
            for file in files:
                if file == 'astute.log':
                    path = os.path.join(root, file)
                    print 'Processing: %s' % path
                    yield path

    def clear_log(self, file):
        if not os.path.isfile(file):
            return
        print 'Clear log: %s' % file
        with open(file, 'w') as f:
            f.truncate()
            f.close()

    def parse_astute_logs(self):
        al = AstuteLog()
        for astute_log in self.astute_logs():
            with open(astute_log, 'r') as log:
                al.parse(log)
        al.output()
        al.clear()

    def parse_puppet_logs(self, enable_sort=False, show_evals=False):
        pl = PuppetLog()
        pl.set_show_evals(show_evals)
        pl.set_enable_sort(enable_sort)
        for puppet_log in self.puppet_logs():
            with open(puppet_log, 'r') as log:
                pl.set_log_name(puppet_log)
                pl.parse(log)
        pl.output()
        pl.clear()

    def clear_astute_logs(self):
        for astute_log in self.astute_logs():
            self.clear_log(astute_log)

    def clear_puppet_logs(self):
        for puppet_log in self.puppet_logs():
            self.clear_log(puppet_log)


##############################################################################

def separator(args):
    if args.puppet and args.astute:
        IO.output('#' * 80 + "\n")


def process_snapshots(args):
    fs = FuelSnapshot()
    for snapshot in args.snapshots:

        if not os.path.isfile(snapshot):
            continue

        fs.open_fuel_snapshot(snapshot)

        if args.astute:
            fs.parse_astute_log()

        separator(args)

        if args.puppet:
            fs.parse_puppet_logs(enable_sort=args.sort, show_evals=args.evals)

        fs.close_fuel_snapshot()


def process_logs(args):
    fl = FuelLogs()
    if args.astute:
        if args.clear:
            fl.clear_astute_logs()
        else:
            fl.parse_astute_logs()

    separator(args)

    if args.puppet:
        if args.clear:
            fl.clear_puppet_logs()
        else:
            fl.parse_puppet_logs(enable_sort=args.sort, show_evals=args.evals)


def options():
    parser = argparse.ArgumentParser()
    parser.add_argument("--astute", "-a", action="store_true", default=False,
                        help='Parse Astute log')
    parser.add_argument("--puppet", "-p", action="store_true", default=False,
                        help='Parse Puppet logs')
    parser.add_argument("--clear",  "-c", action="store_true", default=False,
                        help='Clear the logs on the master node')
    parser.add_argument("--sort",  "-s", action="store_true", default=False,
                        help='Sort Puppet logs by date')
    parser.add_argument("--evals",  "-e", action="store_true", default=False,
                        help='Show Puppet evaltrace lines')
    parser.add_argument("--less",  "-l", action="store_true", default=False,
                        help='Redirect data to the "less" pager')
    parser.add_argument('snapshots', metavar='SNAPSHOT', type=str, nargs='*',
                        help='Take logs from these snapshots', default=[])
    args = parser.parse_args()
    if not args.puppet and not args.astute:
        args.puppet = True
        args.astute = True
    return args


def main():
    args = options()

    if args.less:
        IO.open_pager()

    if len(args.snapshots) == 0:
        process_logs(args)
    else:
        process_snapshots(args)

    if args.less:
        IO.close_pager()

##############################################################################

if __name__ == '__main__':
    main()
