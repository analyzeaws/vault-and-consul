#!/bin/bash
set -e
sudo /bin/bash -c 'echo "export LANG=C.UTF-8" >> /etc/skel/.bashrc'

echo "---- make Apt non interactive"
sudo /bin/bash -c 'echo "force-confnew" >> /etc/dpkg/dpkg.cfg'
sudo /bin/bash -c '[ -f /tmp/dpkg.cfg.update ] && cat /tmp/dpkg.cfg.update >> /etc/sudoers.d/env_keep || echo "no dpkg update" '
sudo /bin/bash -c '[ -f /tmp/apt.conf.update ] && cp /tmp/apt.conf.update /etc/apt/apt.conf || echo "no apt conf update" '
sudo dpkg -l | grep linux-
