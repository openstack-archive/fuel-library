import os.path
import sys
import logging
import argparse
from nose.plugins.manager import PluginManager
from nose.plugins.xunit import Xunit
from ci import Ci

def get_params():
    parser = argparse.ArgumentParser(description="Integration test suite")
    parser.add_argument("-i", "--image", dest="image",
        help="base image path or http://url")
    parser.add_argument("-l", "--level", dest="log_level", type=str,
        help="log level", choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO", metavar="LEVEL")
    parser.add_argument('command', choices=('setup', 'destroy', 'test'), default='test',
        help="command to execute")
    parser.add_argument('arguments', nargs=argparse.REMAINDER, help='arguments for nose testing framework')
    return parser.parse_args()


def nose_runner(params):
    import nose
    import nose.config

    nc = nose.config.Config()
    nc.verbosity = 3
    nc.plugins = PluginManager(plugins=[Xunit()])
    nc.configureWhere(os.path.join(os.path.dirname(os.path.abspath(__file__)),
        params.test_suite))
    nose.main(config=nc, argv=[
                                  __file__,
                                  "--with-xunit",
                                  "--xunit-file=nosetests.xml"
                              ] + params.arguments)


def main():

    params = get_params()

    numeric_level = getattr(logging, params.log_level.upper())
    logging.basicConfig(level=numeric_level)
    logger = logging.getLogger()
    logger.setLevel(numeric_level+1)

    ci = Ci(params.image)

    if params.command == 'setup':
        ci.get_environment_or_create()
    elif params.command == 'destroy':
        ci.destroy_environment()
    else:
        nose_runner(params)



if __name__ == "__main__":
    main()

