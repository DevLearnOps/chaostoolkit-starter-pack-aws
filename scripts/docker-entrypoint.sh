#!/bin/bash -e

export PYTHONPATH="/chaos/modules/:${PYTHONPATH}"
EXPERIMENT_PATH="${EXPERIMENT_PATH-reliability/tasks-failure}"
EXPERIMENT_FILE="${EXPERIMENT_FILE-experiment.yaml}"
ENV_FILE="experiment.env"

cd $EXPERIMENT_PATH

if [[ -e $ENV_FILE ]]; then
    echo "Loading environment from $EXPERIMENT_PATH/$ENV_FILE"
    export $(cat $ENV_FILE | xargs)
fi

CHAOS_CMD="chaos run"
CHAOS_CMD="$CHAOS_CMD --rollback-strategy ${ROLLBACK_STRATEGY-always}"
CHAOS_CMD="$CHAOS_CMD --hypothesis-strategy ${HYPOTHESIS_STRATEGY-default}"
CHAOS_CMD="$CHAOS_CMD --hypothesis-frequency ${HYPOTHESIS_FREQUENCY-10}"

if [[ "$FAIL_FAST" == "true" ]]; then
    CHAOS_CMD="$CHAOS_CMD --fail-fast"
fi

###########################################################
# Journal upload to s3 bucket. Uncomment the lines below
#   to activate the control for all experiments.
###########################################################
# echo "Generating file control for s3 journal upload"
# cat /chaos/scripts/s3-upload.yaml.template | envsubst \
#     > /chaos/scripts/s3-upload.yaml
# 
# CHAOS_CMD="$CHAOS_CMD --control-file=/chaos/scripts/s3-upload.yaml"

CHAOS_CMD="$CHAOS_CMD ${EXPERIMENT_FILE-experiment.yaml}"

# suppressing experiment failure to allow journal upload and reporting
eval "$CHAOS_CMD" || true

python3 /chaos/scripts/upload_and_notify.py
