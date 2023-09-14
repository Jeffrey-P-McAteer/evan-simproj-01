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
if [[ $(date +%s -r "$container_ml" ) -lt $(date +%s --date="12 days ago") ]] ; then
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

# "inc if file does not exist" - shortcut for installing packages using canary files
# OUTSIDE the container instead of inside b/c that's faster.
inc_ifn() {
  canary_file="${root_dir%%/}/$1"
  if [ -e "$canary_file" ] ; then
    echo "Skipping b/c $1 exists >>> " "${@:2}"
  else
    inc "${@:2}"
  fi
}

pacman_setup_complete_flag="$root_dir"/.pacman-setup-complete
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
  inc sh -c "pacman -S --noconfirm --overwrite \* archlinux-keyring"
  inc sh -c "pacman -Syu --noconfirm --overwrite \*"
  inc sh -c "pacman -S --noconfirm --overwrite \* sudo "

  # Setup user 'user' for AUR package building
  inc sh -c "useradd -m -G users,dbus,wheel user"
  inc sh -c "echo \"%wheel ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/enablewheel"

  # Misc build tools
  inc sh -c "pacman -Syu --noconfirm --overwrite \* base-devel git vim curl wget"

  # AUR helper
  inc sh -c "cd /opt && git clone https://aur.archlinux.org/yay-git.git && chown -R user:user /opt/yay-git "
  inc sh -c "sudo -u user sh -c \"cd /opt/yay-git ; makepkg -si --noconfirm \" "

  # ...and IF on Jeff's PC copy his low-sec ssh key in
  if [ -e /j/ident/github_lowsec_key ]; then
    sudo cp /j/ident/github_lowsec_key "$root_dir"/github_id
    inc sh -c "sudo -u user sh -c \"mkdir -p /home/user/.ssh ; echo 'host github.com' > /home/user/.ssh ; echo '  IdentityFile /github_id' >> /home/user/.ssh ; echo '  User git' >> /home/user/.ssh \" "
    inc sh -c "chown user:user /github_id ; chmod 600 /github_id"
  fi

  sudo touch "$pacman_setup_complete_flag"
fi

# Now that we have up-to-date packages, install the things specific to our target software

#inc_ifn /electrostatic_meteor_ablation_sim/.git sh -c \
#  'mkdir -p /electrostatic_meteor_ablation_sim ; git clone https://gitlab.com/oppenheim_public/electrostatic_meteor_ablation_sim.git /electrostatic_meteor_ablation_sim ; chown -R user:user /electrostatic_meteor_ablation_sim'

# Swap out jeff's changes directly
inc_ifn /electrostatic_meteor_ablation_sim/.git sh -c \
  'mkdir -p /electrostatic_meteor_ablation_sim ; git clone https://github.com/Jeffrey-P-McAteer/electrostatic_meteor_ablation_sim.git /electrostatic_meteor_ablation_sim ; chown -R user:user /electrostatic_meteor_ablation_sim'

inc_ifn /usr/include/dfftw.h sh -c \
  'sudo -u user yay -Su --noconfirm fftw2'

inc_ifn /usr/include/dfftw.h sh -c \
  'sudo -u user yay -Su --noconfirm fftw'


inc_ifn /usr/bin/mpicc sh -c \
  'sudo -u user yay -Su --noconfirm openmpi'

inc_ifn /usr/bin/h5pcc sh -c \
  'sudo -u user yay -Su --noconfirm hdf5-openmpi'

inc_ifn /usr/bin/gsl-config sh -c \
  'sudo -u user yay -Su --noconfirm gsl'

# Gdb is great for debugging!
inc_ifn /usr/sbin/gdb sh -c \
  'sudo -u user yay -Su --noconfirm gdb'


# Lastly, run an interactive terminal
cat <<EOF

To compile electrostatic_meteor_ablation_sim:

  > su user
  > cd /electrostatic_meteor_ablation_sim/src
  > make -j4 \\
      'FFTWLIBDIR=/usr/lib' \\
      'MPICXX=mpic++' \\
      'CXXFLAGS+=-fpermissive' \\
      'CXXFLAGS+=-I/electrostatic_meteor_ablation_sim/src/classes' \\
      'CPPFLAGS+=-I/electrostatic_meteor_ablation_sim/src' \\
      'CPPFLAGS+=-D_GNU_SOURCE=1' \\
      'CPPFLAGS+=-D_POSIX_C_SOURCE=200809L' \\
      'CPPFLAGS+=-D_XOPEN_SOURCE=700' \\
      'CPPFLAGS+=-DUSE_FFTW3=1' \\
      'CPPFLAGS+=-DNDIM=3' \\
      'CPPFLAGS+=-DUSE_MPI=1' \\
      'CPPFLAGS+=-DUSE_DOMAINS=1' \\
      'CPPFLAGS+=-DHAVE_SCHED_H=1' \\
      'CPPFLAGS+=-DEPPIC_FFTW_USE_D_PREFIX=1' \\
      'LIBS-=-lrfftw_mpi -lfftw_mpi -lrfftw -lfftw' \\
      'LIBS+=-ldrfftw_mpi -ldfftw_mpi -ldrfftw -ldfftw -lm -lhdf5_hl -lhdf5' \\
      'CPPFLAGS+=-g'

  Run simulation like

    > su user
    > cd /electrostatic_meteor_ablation_sim/src
    > mpiexec -np 32 --oversubscribe ./eppic.x eppic.i

  where -np 32 is the number of MPI "slots" that ./eppic.x can use; ./eppic.x assumes it is
  run through mpiexec, and mpiexec has a number of config options we should read through.

  --oversubscribe says "ignore hardware capabilities and lie to eppic about HW parallelism available"

  To diagnose segfaults, add in GDB like so:

    > mpiexec -np 32 --oversubscribe gdb -batch -ex "run" -ex "bt" -ex "info locals" --args ./eppic.x eppic.i

  Which will print the line of C code and local variable values when the ./eppic.x crashes.

EOF
inc sh -c "cd / ; bash"








