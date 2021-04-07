#! /bin/bash

# run_icafix_verify.sh
# Created: 4/7/2021

# EXAMPLE USAGE
# ./run_icafix_verify.sh

ABCD_CCA_REPLICATION="$(dirname "$PWD")"
# Check for and load config
if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi

. /$SUPPORT_SCRIPTS/stage_3/verify_icafix_outputs.sh $ABCD_CCA_REPLICATION