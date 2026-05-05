#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
CONFIG_FILE="./supervisord.conf"

cat << EOF > ${CONFIG_FILE}
[supervisord]
nodaemon=true

[program:servicetool]
environment=
  PYTHONPATH=%(ENV_SERVICETOOLDIR)s
command=gunicorn -k gevent -b 0.0.0.0:5000 --limit-request-field_size 16384 app:app
autostart = true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF
