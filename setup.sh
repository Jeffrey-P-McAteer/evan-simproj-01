#!/bin/bash

dependencies=(
  mkdir wget date
  sudo
)

for dependency in "${dependencies[@]}" ; do
  if ! which $dependency 2>/dev/null >/dev/null ; then
    echo "Cannot find a required tool '$dependency', please install $dependency and try again."
    exit 1
  fi
done

root_dir="$PWD/container_root"

if ! [ -e "$root_dir" ] || ! [ -e "$root_dir/root" ]; then
  echo "Creating an Arch Linux container at $root_dir"
  sudo mkdir -p "$root_dir"

  dl_url="http://mirror.adectra.com/archlinux/iso/$(date +"%Y.%m.01")/archlinux-bootstrap-x86_64.tar.gz" 
  echo "Downloading an Arch Linux root filesystem from $dl_url"

  wget -qO- "$dl_url" | sudo tar xvz -C "$root_dir" --strip-components=1

fi




