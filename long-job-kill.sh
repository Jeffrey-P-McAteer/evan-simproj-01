#!/bin/bash

set -e

if [[ -z "$long_job_task_name" ]] ; then
  long_job_task_name='evan-simproj-bg-task'
fi

echo "Using long_job_task_name = $long_job_task_name"
echo ''

sudo systemctl stop "$long_job_task_name"

