#!/usr/bin/env bash
#SBATCH --account=askaprt
#SBATCH --cluster=setonix
#SBATCH --cpus-per-task=1
#SBATCH --export=NONE
#SBATCH --job-name=RACS-BACKUP-AUTO
#SBATCH --ntasks=1
#SBATCH --output=slurm-RACS-BACKUP-AUTO_JID-%j.out
#SBATCH --partition=copy
#SBATCH --time=00:30:00
set -e


echo "Explicitly unsetting all SLURM_* environment variables..."
# This is because even with --export=NONE above, SLURM_* environment variables
# are still persisted by sbatch.
for slurmEnvVar in $(env | grep SLURM_ | awk -F'=' '{print $1}'); do
    echo "Unsetting ${slurmEnvVar}..."
    unset "${slurmEnvVar}"
done


ARGUMENT_LIST=(
  "sbid"
)


# Read arguments
opts=$(getopt \
  --longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")" \
  --name "$(basename "$0")" \
  --options "" \
  -- "$@"
)

eval set --$opts

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sbid)
      SBID=$2
      shift 2
      ;;

    *)
      break
      ;;
  esac
done


## Parse arguments
### Second argument is CAL_SBID
### Third argument is the directory containing the data

#TODO: Get these data somehow...
# Can be science or calibrator SBID
DATA_DIR=${3:-"/askapbuffer/scott/askap-scheduling-blocks/${SBID}"}


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
tar \
    --use-compress-program="pigz --best --recursive" \
    -cf ${SBID}.tar.gz \
    ${DATA_DIR}/${SBID} && \
rclone \
    copy \
    -P \
    ${SBID}.tar.gz \
    ${REMOTE_NAME}:${BUCKET_NAME}/

## TODO: Do something on success/failure
# e.g. Emit a message via clink-cli
# Purge data from disk, etc
