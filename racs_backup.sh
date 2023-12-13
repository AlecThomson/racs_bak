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


## Tar up the data
SBID_TAR=${DATA_DIR}/${SBID}.tar
CAL_SBID_TAR=${DATA_DIR}/${CAL_SBID}.tar
tar -cvf ${SBID_TAR} ${DATA_DIR}/${SBID}/
tar -cvf ${CAL_SBID_TAR} ${DATA_DIR}/${CAL_SBID}/

## Ensure bucket exists
# Assuming the remote is called 'askap' 
#   - need to ensure this is in the rclone config
# Here we're also locking in the bucket name to be 'RACSlow3-backup'
rclone mkdir askap:RACSlow3-backup

## Copy the data to the bucket
rclone copy -P ${SBID_TAR} askap:RACSlow3-backup/
rclone copy -P ${CAL_SBID_TAR} askap:RACSlow3-backup/

## TODO: Do something on success/failure
# e.g. Emit a message via clink-cli
# Purge data from disk, etc
