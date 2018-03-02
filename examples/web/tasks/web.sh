#!/bin/bash
set -e

echo '---- install Apache And Redis'

DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y install -y redis-server apache2 apache2-doc apache2-utils
