#!/bin/bash

set -e

if [[ -z "$long_job_task_name" ]] ; then
  long_job_task_name='evan-simproj-bg-task'
fi

if [[ -z "$num_mpi_threads" ]] ; then
  num_mpi_threads=$(nproc --all)
fi

if [[ -z "$root_dir" ]] ; then
  root_dir="$PWD/container_root"
fi

echo "Using long_job_task_name = $long_job_task_name across $num_mpi_threads MPI threads"
echo ''

echo "Running: /electrostatic_meteor_ablation_sim/src/eppic.x $@"
echo "as an mpiexec task with GDB attached; task name is $long_job_task_name"
echo ''

# Prevent old service definitions from blocking new task
sudo systemctl reset-failed || true

if ! [[ -z "$1" ]] && ! [[ -e "$root_dir/$1" ]] ; then
  cat <<EOF

WARNING: the file $1 specified does not exist within
the container. Host path tested was $root_dir/$1

EOF
fi

if ! [[ -z "$DEBUG" ]] ; then
  echo "DEBUG is set, running with gdb for segfault backtraces"
  sudo systemd-run --unit="$long_job_task_name" --remain-after-exit --same-dir \
    --quiet --no-block \
    --setenv=last_cmd_chdir="/electrostatic_meteor_ablation_sim" \
    --setenv=container_hostname="$container_hostname" \
    ./setup.sh sudo -u user \
      mpiexec -np "$num_mpi_threads" \
        /electrostatic_meteor_ablation_sim/src/eppic.x "$@"

else
  echo "DEBUG not set, running without gdb for segfault backtraces"
  sudo systemd-run --unit="$long_job_task_name" --remain-after-exit --same-dir \
    --quiet --no-block \
    --setenv=last_cmd_chdir="/electrostatic_meteor_ablation_sim" \
    --setenv=container_hostname="$container_hostname" \
    ./setup.sh sudo -u user \
      mpiexec -np "$num_mpi_threads" gdb -batch -ex "run" -ex "bt" -ex "info locals" --args \
        /electrostatic_meteor_ablation_sim/src/eppic.x "$@"
fi

echo 'Job spawned!'
echo 'Use ./long-job-output.sh to attach to output.'
echo 'Use ./long-job-kill.sh to stop a running job.'
echo ''


