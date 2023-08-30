#!/bin/bash

set -e

dependencies=(
  mkdir wget date touch
  sudo sed curl tee
  systemd-nspawn
)

for dependency in "${dependencies[@]}" ; do
  if ! which $dependency 2>/dev/null >/dev/null ; then
    echo "Cannot find a required tool '$dependency', please install $dependency and try again."
    exit 1
  fi
done

container_hostname='evan-simproj-01'

if [[ -z "$root_dir" ]] ; then
  root_dir="$PWD/container_root"
fi

echo "Using Root Directory $root_dir for container."

if ! [[ -e "$root_dir" ]] || ! [[ -e "$root_dir/root" ]]; then
  echo "Creating an Arch Linux container at $root_dir"
  sudo mkdir -p "$root_dir"

  dl_url="http://mirror.adectra.com/archlinux/iso/$(date +"%Y.%m.01")/archlinux-bootstrap-x86_64.tar.gz" 
  echo "Downloading an Arch Linux root filesystem from $dl_url"

  wget -qO- "$dl_url" | sudo tar xvz -C "$root_dir" --strip-components=1

fi

container_ml="$root_dir"/etc/pacman.d/mirrorlist
if [[ $(date +%s -r "$container_ml" ) -lt $(date +%s --date="3 days ago") ]] ; then
  if [[ -e /etc/pacman.d/mirrorlist ]] ; then
    echo "Copying your mirrorlist into the container"
    sudo cp /etc/pacman.d/mirrorlist "$container_ml"
  else
    echo "Downloading a mirrorlist from https://archlinux.org/mirrorlist to $container_ml"
    curl 'https://archlinux.org/mirrorlist/?country=US&protocol=http&protocol=https&ip_version=4' | sed 's/#Server/Server/g' | sudo tee "$container_ml"
  fi
fi

if ! grep "$container_hostname" "$root_dir"/etc/hostname 2>/dev/null >/dev/null ; then
  echo "$container_hostname" | sudo tee "$root_dir"/etc/hostname
fi


# We now have a container ready to be booted; the "inc" command we
# define here can quickly run a setup/install command in the container.
# This can also be tweaked to swap out systemd-nspawn with runc or another
# container runtime if we prefer something different. nspawn is on most machines though.
inc() {
  echo "Running in container >>> " "$@"
  sudo systemd-nspawn \
    --capability=all \
    --machine="$container_hostname" \
    -D "$root_dir" \
    "$@"
}

pacman_setup_complete_flag="$root_dir"/root/.pacman-setup-complete
if ! [ -e "$pacman_setup_complete_flag" ] ; then
  # Enable multilib!
  inc sh -c "echo '[multilib]' >> /etc/pacman.conf"
  inc sh -c "echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf"
    # Turn off signature checks
  inc sh -c "sed -i \"s/SigLevel.*=.*/SigLevel = Never/g\" /etc/pacman.conf"
    # Turn off space check
  inc sh -c "sed -i \"s/^CheckSpace.*/#CheckSpace/g\" /etc/pacman.conf"

    # We'd like utf-8 locale
  inc sh -c "echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen"
  inc sh -c "locale-gen"
  inc sh -c "echo 'LANG=\"en_US.UTF-8\"' > /etc/locale.conf"

  inc sh -c "pacman -Sy"
  inc sh -c "pacman-key --init"
  inc sh -c "pacman -S --noconfirm archlinux-keyring"
  inc sh -c "pacman -Syu --noconfirm"
  inc sh -c "pacman -S --noconfirm sudo "

  # Setup user 'user' for AUR package building
  inc sh -c "useradd -m -G users,dbus,wheel user"
  inc sh -c "echo \"%wheel ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/enablewheel"

  # Misc build tools
  inc sh -c "pacman -Syu --noconfirm base-devel git vim curl wget"

  # AUR helper
  inc sh -c "cd /opt && git clone https://aur.archlinux.org/yay-git.git && chown -R user:user /opt/yay-git "
  inc sh -c "sudo -u user sh -c \"cd /opt/yay-git ; makepkg -si --noconfirm \" "

  sudo touch "$pacman_setup_complete_flag"
fi

# Now that we have up-to-date packages, install the things specific to our target software

inc sh -c "[ -e /electrostatic_meteor_ablation_sim/.git ] || ( mkdir -p /electrostatic_meteor_ablation_sim ; git clone https://gitlab.com/oppenheim_public/electrostatic_meteor_ablation_sim.git )"

# For all dependencies we check for a canary file before running install; if it's already installed do nothing
inc sh -c "[ -e /usr/lib/libfftw3f.so ] || sudo -u user yay -Syu --noconfirm fftw2"


inc sh -c "[ -e /usr/bin/mpicc ] || pacman -Syu --noconfirm openmpi"
inc sh -c "[ -e /usr/bin/h5cc ] || pacman -Syu --noconfirm hdf5"

# Run an interactive terminal
cat <<EOF

To compile electrostatic_meteor_ablation_sim:

  > cd /electrostatic_meteor_ablation_sim/src
  > make 'MPICXX=mpic++' 'CXXFLAGS+=-fpermissive' 'CXXFLAGS+=-I/electrostatic_meteor_ablation_sim/src/classes' 'CPPFLAGS+=-I/electrostatic_meteor_ablation_sim/src'


EOF
inc sh -c "cd /electrostatic_meteor_ablation_sim ; bash"








