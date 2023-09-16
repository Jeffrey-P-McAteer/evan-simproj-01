
# Simulator Setup script for some Academic nonsense

# Setup

```bash
# requires some tools like systemd-nspawn and sudo;
# see messages for details if a tool is missing.
./setup.sh

# If you want to throw data on an external disk, override the root_dir variable
# with the folder to be used for data.
root_dir=/mnt/scratch/containers/evan-simproj-01 ./setup.sh

# To spawn a long-running job that does not need a terminal attached / active connection
# of any kind:

./long-job-spawn.sh /electrostatic_meteor_ablation_sim/input_files/lowres_test1.i

# To read output of a long job:

./long-job-output.sh

# To kill a long running job:

./long-job-kill.sh


# Running off tmpfs (basically running everything from RAM on a large machine)
# Step 1: create a folder and mount a tmpfs filesystem on top of it, in this case we pick 210gb:
sudo mount -t tmpfs -o size=210G tmpfs /projects/evan-ram-simproj
# Step 2: rsync an existing copy of evan-simproj-01 to the folder in ram:
sudo rsync -aAXHv /projects/evan-fast-simproj/evan-simproj-01/. /projects/evan-ram-simproj
# Step 3:
cd /projects/evan-ram-simproj
./long-job-spawn.sh /electrostatic_meteor_ablation_sim/input_files/lowres_test1.i
# Step 4:
#   Remember to copy files OUT of /projects/evan-ram-simproj, because they're going to be lost on reboot.


```

# Network files / non-linux user file permission hiccup fixes

```bash
# Find all files under input_files and make them world read/write/executable (matching windows permissions)
find ./container_root/electrostatic_meteor_ablation_sim/input_files -exec sudo chmod 777 {} \;

```


## References

SW we're standing up

  - https://gitlab.com/oppenheim_public/electrostatic_meteor_ablation_sim

