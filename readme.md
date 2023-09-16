
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


```


## References

SW we're standing up

  - https://gitlab.com/oppenheim_public/electrostatic_meteor_ablation_sim

