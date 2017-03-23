import argparse
import os

import six
import yaml


PROVISIONING_IMAGES_PATH = "/var/www/nailgun/targetimages"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--provision-yaml", action="store",
                        dest="provision_yaml", required=True,
                        help="Path to provision yaml file")
    args, other = parser.parse_known_args()

    with open(args.provision_yaml) as f:
        data = yaml.safe_load(f)
    images_data = data["provision"]["image_data"]

    files = []
    for image_path, image_data in six.iteritems(images_data):
        file_name = os.path.basename(
            six.moves.urllib.parse.urlsplit(image_data['uri']).path)
        files.append(os.path.join(
            PROVISIONING_IMAGES_PATH, file_name)
        )
        if image_path == '/':
            yaml_name = '{0}.{1}'.format(file_name.split('.')[0], 'yaml')
            files.append(os.path.join(
                PROVISIONING_IMAGES_PATH, yaml_name))

    for f in files:
        os.remove(f)


if __name__ == "__main__":
    main()
