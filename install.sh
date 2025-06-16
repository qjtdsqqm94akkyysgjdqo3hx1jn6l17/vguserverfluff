#!/bin/sh

echo "Adding the files..."

(cp -iv ./fancy-ify.sh /etc/profile.d/) || echo "File not added."
(cp -iv ./check_quota.sh /usr/bin/)     || echo "File not added."

echo "Script will exit."
