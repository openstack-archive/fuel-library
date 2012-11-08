import logging
import argparse
import devops
import os

def get_params():
    parser = argparse.ArgumentParser(description="Integration test suite")
    parser.add_argument('command',
        choices=('setup', 'destroy', 'resume', 'suspend'),
        default='setup',
        help="command to execute")
    return parser.parse_args()


def main():
    params = get_params()
    logging.getLogger().setLevel(logging.DEBUG)

    name = os.environ.get('ENV_NAME', 'recipes')
    environment = devops.load(name)

    if params.command == 'destroy':
        devops.destroy(environment)
    if params.command == 'suspend':
        for node in environment.nodes:
            node.suspend()
    if params.command == 'resume':
        for node in environment.nodes:
            node.suspend()

if __name__ == "__main__":
    main()

