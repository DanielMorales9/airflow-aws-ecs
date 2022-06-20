#!/bin/bash
set -ex
echo "Starting up airflow $1"

# Install boto and awscli for the seed dag
python -m pip install awscli --user

# Install python packages through requirements.txt
if [[ -f "${AIRFLOW_HOME}/startup/requirements.txt" ]]; then
    python -m pip install -r ${AIRFLOW_HOME}/startup/requirements.txt --user
fi

case "$1" in

  "webserver")
    airflow webserver
    ;;

  "scheduler")
    airflow scheduler
    ;;

  "worker")
    airflow celery worker
    ;;

  *)
    exit 128 # invalid argument
    ;;
esac
