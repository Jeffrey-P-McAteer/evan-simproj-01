#!/bin/bash

set -e

if [[ -z "$long_job_task_name" ]] ; then
  long_job_task_name='evan-simproj-bg-task'
fi

echo "Using long_job_task_name = $long_job_task_name"
echo ''

echo "Running: /electrostatic_meteor_ablation_sim/src/eppic.x $@"
echo "as an mpiexec task with GDB attached; task name is $long_job_task_name"
echo ''

# Prevent old service definitions from blocking new task
sudo systemctl reset-failed || true

sudo systemd-run --unit="$long_job_task_name" --remain-after-exit --same-dir \
  --quiet --no-block --setenv=last_cmd_chdir="/electrostatic_meteor_ablation_sim" \
  ./setup.sh sudo -u user \
    mpiexec gdb -batch -ex "run" -ex "bt" -ex "info locals" --args \
      /electrostatic_meteor_ablation_sim/src/eppic.x "$@"


echo 'Job spawned!'
echo 'Use ./long-job-output.sh to attach to output.'
echo 'Use ./long-job-kill.sh to stop a running job.'
echo ''


