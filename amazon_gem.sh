#!/usr/bin/env bash
# This bootstraps Puppet on Amazon Linux (Enterprise Linux 6)
# It has been tested on Amazon Linux 2014.03 64bit

set -e

if [ "$EUID" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

if which puppet > /dev/null 2>&1; then
  echo "Puppet is already installed."
  exit 0
fi

# Not needed for install but nice to have enabled
yum-config-manager --enable epel > /dev/null

# Install Puppet using rubygems
# Amazon Linux has had a bad habit of breaking puppet 3.x due to ruby
# upgrades and missing package dependencies
echo "Installing puppet via rubygems"
yum -y install rubygems ruby-devel augeas augeas-devel augeas-libs > /dev/null || rc=$?
gem install puppet ruby-augeas ruby-nagios --no-rdoc --no-ri > /dev/null || rc=$?

if [ -n "$rc" ]; then
  echo "Puppet failed to install!"
  exit $rc
fi
echo "Puppet installed!"
