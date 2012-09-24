#!/usr/bin/env python

import sys
import re
import shlex
import yaml
import argparse
import logging
import subprocess
import StringIO

console = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s %(name)-12s %(levelname)-8s %(message)s')
console.setFormatter(formatter)
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
logger.addHandler(console)

def system_command(command):
    
    commands = [ i.strip() for i in re.split(ur'\|', command)]

    process = []
    process.append(subprocess.Popen(shlex.split(commands[0]), 
                                    stdin=None, 
                                    stdout=subprocess.PIPE, 
                                    stderr=subprocess.PIPE))
    
    for c in commands[1:]:
        process[-1].wait()
        process.append(subprocess.Popen(shlex.split(c), 
                                        stdin=process[-1].stdout, 
                                        stdout=subprocess.PIPE, 
                                        stderr=subprocess.PIPE))

    process[-1].wait()

    serr = []
    for p in process:
        serr += [ err.strip() for err in p.stderr.readlines() ]
        
    returncode = process[-1].returncode
        
    # if expected_resultcodes and not returncode in expected_resultcodes:
    #     logger.error("Command '%s' returned %d, stderr: %s" % \
    #                  (command, returncode, '\n'.join(serr)))
    # else:
    #     logger.debug("Command '%s' returned %d" % (command, returncode))
        
    return returncode


def is_system_exist(system_name):
    command = """/usr/bin/cobbler system find \
--name=%s | grep \"^%s$\" """ % (system_name, system_name)

    logger.debug("Running command: %s" % command)
    code = system_command(command)
    return code == 0

def update_system(system_name, system_dict):
    addedit = 'add'
    if is_system_exist(system_name):
        addedit = 'edit'

    command = ["""/usr/bin/cobbler system %s --name='%s'""" % \
               (addedit, system_name)]
    
    for opt in system_dict:
        if opt in ('interfaces',):
            continue
        command.append("""--%s='%s'""" % (opt, system_dict[opt]))

    command = " ".join(command)
    
    logger.debug("Running command: %s" % command)
    return system_command(command) == 0
    
    
def update_system_interfaces(system_name, interfaces_dict):
    addedit = 'add'
    if is_system_exist(system_name):
        addedit = 'edit'

    code = set([0])
    for interface_name in interfaces_dict:
        logger.debug("Defining interface: %s" % interface_name)
        int_opts = interfaces_dict[interface_name]
        
        command = ["""/usr/bin/cobbler system %s --name='%s' \
--interface='%s'""" % (addedit, system_name, interface_name)]
                   
        for opt in int_opts:
            logger.debug("Interface option: %s = %s" % (opt, int_opts[opt]))
            command.append("""--%s='%s'""" % (opt, int_opts[opt]))

        command = " ".join(command)
        
        logger.debug("Running command: %s" % command)
        code.union(set([system_command(command)]))

    return len(code) == 0
            
def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file", dest="file", 
                        metavar="YAML_FILE", type=str,
                        help="nodes yaml file")
    
    params = parser.parse_args()

    if params.file is None:
        parser.error("Yaml file must be defined with -f option.")
    
    with open(params.file, 'r') as file:
        nodes = yaml.load(file.read())

    for name in nodes:
        logger.debug("Defining node: %s" % name)
        update_system(name, nodes[name])
        update_system_interfaces(name, nodes[name]['interfaces'])

if __name__ == "__main__":
    main()
