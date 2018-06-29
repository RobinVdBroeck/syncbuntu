#!/bin/bash

#   Copyright 2018 Robin Van den Broeck
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Requires 1 argument: the message
print_with_prefix() {
    echo "[Syncbuntu] $1"
}

print_with_prefix "Syncbuntu installs ppas and apts"


if [ "$EUID" -ne 0 ]; then
  print_with_prefix "Please run as root"
  exit 1
fi

if [ $# -eq 0 ]; then
    print_with_prefix "Invalid syntax"
    print_with_prefix "Syncbuntu requires following syntax: syncbuntu <FILE>"
    print_with_prefix "File is a json file containing 2 arrays: ppa, apt"
    exit 1
fi

if [ ! -f $1 ]; then
    print_with_prefix "File $FILE does not exist"
    exit 1
fi

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' jq | grep "install ok installed")
if [ "" == "$PKG_OK" ]; then
    print_with_prefix "Dependency jq not met, installing it"
    apt-get install -y jq
fi

print_with_prefix "Adding ppas"
for repository in $(jq '.ppa' $1 | grep -P \" | tr -d "\"\t, " | sed -e "s/\n/ /" | sed -e 's/^/ppa:/')
do
    print_with_prefix "Adding repository $repository"
    add-apt-repository --no-update -y $repository
done

print_with_prefix "Updating registery"
apt-get update
print_with_prefix "Installing packages"
for package in $(jq '.apt' $1 | grep -P \" | tr -d "\"\t, ")
do
    print_with_prefix "Installing $package"
    apt-get install -y $package
done
print_with_prefix "Upgrading packages"
apt-get upgrade -y