#!/bin/sh

## This script enables any function/command that could be
## launch a start such as TRACE_ON()

set -e

if [ -n "$ENABLE_TRACE" ];
  isql -P $( cat /settings/dba_password) << EOL
  TRACE_ON();
EOL
fi