import logging
import argparse
import devops
import os

def get_params():
    parser = argparse.ArgumentParser(description="Integration test suite")
    parser.add_argument('command', choices=('setup', 'destroy'),
        default='setup',
        help="command to execute")
    return parser.parse_args()

def main():
    params = get_params()
    logging.getLogger().setLevel(logging.DEBUG)

    if params.command == 'destroy':
        name = os.environ.get('ENV_NAME', 'recipes')
        devops.destroy(devops.load(name))

if __name__ == "__main__":
    main()

