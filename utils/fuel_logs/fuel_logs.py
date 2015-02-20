#!/usr/bin/env python
import tarfile
import sys
import os
import re
import argparse


class AstuteLog:
    @classmethod
    def parse(cls, content):
        if type(content) == file:
            content = content.read()
        if type(content) == str:
            content = content.splitlines()
        for record in cls.each_record(content):
            cls.rpc_call(record)
            cls.rpc_cast(record)
            cls.task_status(record)

    @classmethod
    def each_record(cls, content):
        record = ''
        date_regexp = re.compile('^\d+-\d+-\S+\s')
        for line in content:
            if re.match(date_regexp, line):
                yield record
                record = line
            else:
                record += line
        yield record

    @classmethod
    def rpc_call(cls, record):
        if 'Processing RPC call' in record:
            print record.strip()

    @classmethod
    def rpc_cast(cls, record):
        if 'Casting message to Nailgun' in record:
            if 'deploying' in record:
                return
            if 'provisioning' in record:
                return
            print record.strip()

    @classmethod
    def task_status(cls, record):
        if 'Task' in record:
            if 'deploying' in record:
                return
            print record.strip()


class PuppetLog:
    @classmethod
    def parse(cls, content):
        if type(content) == file:
            content = content.read()
        if type(content) == str:
            content = content.splitlines()
        for line in content:
            cls.err_line(line)

    @classmethod
    def err_line(cls, line):
        if 'err:' in line:
            print line.strip()


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
        AstuteLog.parse(log)

    def puppet_logs(self):
        for log in self.snapshot.getmembers():
            if not log.isfile():
                continue
            if log.name.endswith('/puppet-apply.log'):
                yield log

    def parse_puppet_logs(self):
        for log in self.puppet_logs():
            name = log.name
            print ">>> %s" % name
            content = self.snapshot.extractfile(log)
            PuppetLog.parse(content)


class FuelLogs:
    @classmethod
    def puppet_logs(cls):
        for root, dirs, files in os.walk('/var/log'):
            for file in files:
                if file == 'puppet-apply.log':
                    path = os.path.join(root, file)
                    print 'Processing: %s' % path
                    yield path

    @classmethod
    def astute_logs(cls):
        for root, dirs, files in os.walk('/var/log'):
            for file in files:
                if file == 'astute.log':
                    path = os.path.join(root, file)
                    print 'Processing: %s' % path
                    yield path

    @classmethod
    def clear_log(cls, file):
        if not os.path.isfile(file):
            return
        print 'Clear log: %s' % file
        with open(file, 'w') as f:
            f.truncate()
            f.close()

#############################################################

parser = argparse.ArgumentParser()
parser.add_argument("--astute", "-a", action="store_true", default=False, help='Parse Astute log')
parser.add_argument("--puppet", "-p", action="store_true", default=False, help='Parse Puppet logs')
parser.add_argument("--clear",  "-c", action="store_true", default=False, help='Clear the logs on the master node')
parser.add_argument('snapshots', metavar='SNAPSHOT', type=str, nargs='*',
                    help='Take logs from these snapshots', default=[])
args = parser.parse_args()

if not args.puppet and not args.astute:
    args.puppet = True
    args.astute = True

if len(args.snapshots) == 0:
    print 'Looking for log files at /var/log'
    if args.astute:
        for astute_log in FuelLogs.astute_logs():
            if args.clear:
                FuelLogs.clear_log(astute_log)
            else:
                with open(astute_log, 'r') as log:
                    AstuteLog.parse(log)

    if args.puppet:
        for puppet_log in FuelLogs.puppet_logs():
            if args.clear:
                FuelLogs.clear_log(puppet_log)
            else:
                with open(puppet_log, 'r') as log:
                    PuppetLog.parse(log)
else:
    FS = FuelSnapshot()
    for snapshot in args.snapshots:
        if not os.path.isfile(snapshot):
            continue
        FS.open_fuel_snapshot(snapshot)
        if args.astute:
            FS.parse_astute_log()
        if args.puppet:
            FS.parse_puppet_logs()
        FS.close_fuel_snapshot()