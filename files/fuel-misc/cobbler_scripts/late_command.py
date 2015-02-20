#!/usr/bin/python
#
#    Copyright (C) 2011 Mirantis Inc.
#
#    Authors: Vladimir Kozhukalov <vkozhukalov@mirantis.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, version 3 of the License.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


from base64 import b64encode
from cStringIO import StringIO
from gzip import GzipFile
import commands, os


TEMPLATE_FILE = (
    "sh -c 'filename=${1}; shift; echo ${0} | base64 --decode | "
    "gunzip -c > ${filename} && chmod %(mode)s ${filename}' "
    "%(content64)s %(destfile)s"
)


TEMPLATE_COMMAND = (
    "sh -c 'echo ${0} | base64 --decode | gunzip -c | sh -' %(content64)s"
)


TEMPLATE_FILE_PLAIN = (
    "sh -c 'filename=${1}; shift; echo ${0} | base64 --decode "
    "> ${filename} && chmod %(mode)s ${filename}' "
    "%(content64)s %(destfile)s"
)


TEMPLATE_COMMAND_PLAIN = (
    "sh -c 'echo ${0} | base64 --decode | sh -' %(content64)s"
)


def base64_gzip(content, gzip=True):
    """
    This method returns content gzipped and then base64 encoded
    so such line can be inserted into preseed file
    """
    if gzip:
        gzipped = StringIO()
        gzip_file = GzipFile(fileobj=gzipped, mode="wb", compresslevel=9)
        gzip_file.write(content)
        gzip_file.close()
        content2 = gzipped.getvalue()
    else:
        content2 = content
    return b64encode(content2)


def get_content(source, source_method):
    if source_method == 'file':
        try:
            f = open(source, 'r')
            content = f.read()
            f.close()
        except:
            return ""
        else:
            return content
    return source


def get_content64(source, source_method, gzip=True):
    return base64_gzip(get_content(source, source_method), gzip).strip()


def late_file(source, destfile, source_method='file', mode='0644', gzip=True):
    if gzip:
        return TEMPLATE_FILE % {
            'mode': mode,
            'content64': get_content64(source, source_method, True),
            'destfile': destfile,
        }
    else:
        return TEMPLATE_FILE_PLAIN % {
            'mode': mode,
            'content64': get_content64(source, source_method, False),
            'destfile': destfile,
        }


def late_command(source, source_method='file', gzip=True):
    if gzip:
        return TEMPLATE_COMMAND % {
            'content64': get_content64(source, source_method, True)
        }
    else:
        return TEMPLATE_COMMAND_PLAIN % {
            'content64': get_content64(source, source_method, False)
        }
