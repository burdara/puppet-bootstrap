#!/usr/bin/env bash
# This bootstraps Puppet on Amazon Linux (Enterprise Linux 6)
# It has been tested on Amazon Linux 2014.03 64bit
#
# Install Puppet using rubygems
# Amazon Linux has had a bad habit of breaking puppet 3.x due to ruby
#   upgrades and missing package dependencies
set -e

if [ "$EUID" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

function _info {
  echo -e "\e[1m\e[34m[INFO ] ${1}\e[0m"
}

function _error {
  echo -e "\e[1m\e[31m[ERROR] ${1}\e[0m"	
}

function _install_package {
  [[ -z "$1" ]] && _error "missing package_name argument" && return 1
  yum list installed "$1" &>/dev/null && _info "$1 package is already installed" && return 0
  _info "installing $1" && yum -y install "$1"
  local rc=$?
  [[ $rc -ne 0 ]] && _error "failed to install package $1" && return $?
  _info "$1 package is installed"
}

function _install_gem {
  [[ -z "$1" ]] && _error "missing gem_name argument" && return 1
  [[ $(gem list "$1") =~ "$1" ]] && _info "$1 gem is already installed" && return 0
  [[ -n "$2" ]] && local version_opt="-v $2"
  _info "installing $1" && gem install "$1" $version_opt --no-rdoc --no-ri
  local rc=$?
  [[ $rc -ne 0 ]] && _error "failed to install gem $1" && return $?
  _info "$1 package is installed"
}

# Not needed for install but nice to have enabled
yum-config-manager --enable epel > /dev/null

_info "Installing puppet via rubygems"

# Scan through commands to see if specific versions are set
while [[ -n "$1" ]]; do
  case "$1" in
    --puppetver) shift
      _puppetver="$1"
      ;;
  esac
  shift
done

for _package in rubygems ruby-devel augeas augeas-devel augeas-libs; do 
  _install_package "$_package" || rc=$?
done
for _gem in puppet ruby-augeas ruby-nagios; do

  [[ "$_gem" == "puppet" && -n "$_puppetver" ]] && _gem_version="$_puppetver"
    _install_gem "$_gem" "$_gem_version" || rc=$?
    _gem_version=""

done

if [ -n "$rc" ]; then
  _error "Puppet and/or dependencies failed to install!"
  exit $rc
fi
_info "Puppet installed!"
