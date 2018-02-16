#!/bin/bash
set -e
my_dir="$(dirname "$0")"
# load our helper functions
source $my_dir/common.sh

# check that the tools we require are present
package_check

#
# base.sh DIR TARGET BASE_NAME
DIR="$1"
NAME="$2"
BASE_NAME="$4"
PACKER_CONFIG="$3"
if [[ -z "$DIR" ]]; then
    echo "please specify the directory containing the all the various template(s) as first argument"
    exit 1
fi
if [[ -z "$NAME" ]]; then
    echo "please specify the name of the template to use as second argument"
    exit 1
fi
if [[ -z "$BASE_NAME" ]]; then
    echo "No base AMI given, if AMI is required to build upon a base AMI, provide base AMI name as 4th argument"
else
    BASE_BUILT=$(base_rebuilt $BASE_NAME)
    AMI_BASE="$(get_base_ami "$BASE_BUILT" "$BASE" "$BASE_NAME")"
fi
if [[ -z "$PACKER_CONFIG" ]]; then
    echo "please specify the json file containing aws keys, and other variables for template as 3rd argument"
    exit 1
else
  AWS_ACCESS_KEY_ID=($(jq -r '.aws_access_key_id' $PACKER_CONFIG))
  AWS_SECRET_ACCESS_KEY=($(jq -r '.aws_secret_access_key' $PACKER_CONFIG))
  REGION=($(jq -r '.region' $PACKER_CONFIG))
fi
echo "latest $DIR build already exists: $TAG_EXISTS"

SHA=$(git ls-tree HEAD "$DIR" | cut -d" " -f3 | cut -f1)
echo "SHA=$SHA"
TAG_EXISTS=$(tag_exists $SHA)
echo "Tag Exists=$TAG_EXISTS"

if [ "$TAG_EXISTS" = "false" ]; then
    packer build -var ami_sha=$SHA --var-file=$PACKER_CONFIG ${DIR}/$NAME.json
else
    touch manifest-${NAME}.json
fi
