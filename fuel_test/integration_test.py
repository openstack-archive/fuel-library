import logging
import argparse
from ci import Ci

def get_params():
    parser = argparse.ArgumentParser(description="Integration test suite")
    parser.add_argument("-i", "--image", dest="image",
        help="base image path or http://url")
    parser.add_argument("-l", "--level", dest="log_level", type=str,
        help="log level", choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO", metavar="LEVEL")
    parser.add_argument('command', choices=('setup', 'destroy'),
        default='setup',
        help="command to execute")
    return parser.parse_args()

def main():
    params = get_params()

    numeric_level = getattr(logging, params.log_level.upper())
    logging.basicConfig(level=numeric_level)
    logger = logging.getLogger()
    logger.setLevel(numeric_level + 1)

    ci = Ci(params.image)

    if params.command == 'setup':
        ci.get_environment_or_create()
    elif params.command == 'destroy':
        ci.destroy_environment()

if __name__ == "__main__":
    main()

