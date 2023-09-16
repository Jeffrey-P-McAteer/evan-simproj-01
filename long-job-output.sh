#!/bin/bash

set -e

if [[ -z "$long_job_task_name" ]] ; then
  long_job_task_name='evan-simproj-bg-task'
fi

echo "Using long_job_task_name = $long_job_task_name"
echo ''

if systemctl is-active --quiet "$long_job_task_name" ; then
  sudo journalctl -n 9999 -f -u "$long_job_task_name"
else
  sudo journalctl -n 9999 --no-pager -u "$long_job_task_name"
fi

