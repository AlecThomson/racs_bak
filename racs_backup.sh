#!/usr/bin/env bash

## Parse arguments
### First argument is SBID
### Second argument is CAL_SBID
### Thrid argument is the directory containing the data

#TODO: Get these data somehow...
SBID=$1
CAL_SBID=$2
DATA_DIR=$3

## Load up appropriate modules
module load rclone
# TODO load clink-cli??

## Rclone config
# Assuming the remote is called 'askap' 
#   - need to ensure this is in the rclone config
# Here we're also locking in the bucket name to be 'RACSlow3-backup'
BUCKET_NAME="RACSlow3-backup"
REMOTE_NAME="askap"


## Ensure bucket exists
rclone mkdir ${REMOTE_NAME}:${BUCKET_NAME}

## Tar up the data
## Copy the data to the bucket
# TODO: Decide on 'copy' or 'move'
# The latter will delete the data from disk on success
## Use pigz for compression
for sb in ${SBID} ${CAL_SBID}; do
    tar \
        --use-compress-program="pigz --best --recursive" \
        -cf ${sb}.tar.gz \
        ${DATA_DIR}/${sb} && \
    rclone \
        copy \
        -P \
        ${sb}.tar.gz \
        ${REMOTE_NAME}:${BUCKET_NAME}/
done

## TODO: Do something on success/failure
# e.g. Emit a message via clink-cli
# Purge data from disk, etc
