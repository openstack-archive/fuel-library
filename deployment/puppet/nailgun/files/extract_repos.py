#!/usr/bin/env python
# coding: utf-8

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

from __future__ import print_function

# argparse wasn't a part of standard python library till python2.7. so
# we're going to use optparse here, since we won't wrap this script
# into an rpm package and therefore unable to install python-argparse.
import optparse
import os
import shutil
import subprocess
import sys
import tempfile


def parse_arguments(argv):
    """Parse a command line arguments and return its outcome.

    :param argv: a list of arguments to parse from
    :returns: an object with parsed options
    """
    parser = optparse.OptionParser(
        usage=(
            '%prog input_image output_dir'),
        description=(
            'Extracts repos from a given image and save them into '
            'output directory.'))

    options, args = parser.parse_args(argv)

    # we have two mandatory arguments; without them it makes
    # no sense to continue.
    if len(args) < 2:
        parser.print_usage()
        parser.exit(1)

    # unlike argparse, the optparse doesn't support names for
    # positional arguments. so let's simulate this is order
    # to provide a convenient interface and be more like argparse
    # for outer world.
    setattr(options, 'image', args[0])
    setattr(options, 'output', args[1])

    return options


def extract_repos(image, output):
    """Extracts repos from a given image to a given output folder.

    In short, the following actions will be performed:

        image/pool -> output/pool
        iamge/dists -> output/dists
        image/install -> output/images

    :param image: a path to image
    :param output: a path to output folder
    """
    mount_point = tempfile.mkdtemp()

    try:
        print('Try to mount', image, 'to', mount_point)
        subprocess.call(['mount', '-o', 'loop', image, mount_point])

        if not os.path.exists(output):
            os.makedirs(output)

        print('Extracting repos...')
        shutil.copytree(
            os.path.join(mount_point, 'pool'),
            os.path.join(output, 'pool'))
        shutil.copytree(
            os.path.join(mount_point, 'dists'),
            os.path.join(output, 'dists'))
        shutil.copytree(
            os.path.join(mount_point, 'install'),
            os.path.join(output, 'images'))
    finally:
        subprocess.call(['umount', mount_point])
        shutil.rmtree(mount_point)

    print('Done')


def main(argv):
    arguments = parse_arguments(argv)
    extract_repos(arguments.image, arguments.output)


if __name__ == '__main__':
    main(sys.argv[1:])
