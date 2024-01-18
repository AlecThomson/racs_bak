#!/usr/bin/env bash
#SBATCH --account=askaprt
#SBATCH --cluster=setonix
#SBATCH --cpus-per-task=1
#SBATCH --export=NONE
#SBATCH --job-name=RACS-BACKUP-AUTO
#SBATCH --ntasks=1
#SBATCH --output=slurm-RACS-BACKUP-AUTO_JID-%j.out
#SBATCH --partition=copy
#SBATCH --time=04:00:00
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

: ${SBID?Need a value}

## Parse arguments
### Second argument is CAL_SBID
### Third argument is the directory containing the data

#TODO: Get these data somehow...
# Can be science or calibrator SBID
DATA_DIR=${3:-"/askapbuffer/scott/askap-scheduling-blocks/${SBID}"}


## Load up appropriate modules
module load rclone/1.62.2

## Rclone config
# Assuming the remote is called 'askap' 
#   - need to ensure this is in the rclone config
# Here we're also locking in the bucket name to be 'RACSlow3-backup'
BUCKET_NAME="racslow3-backup"
REMOTE_NAME="askap"


## Ensure bucket exists
rclone mkdir ${REMOTE_NAME}:${BUCKET_NAME}

## Tar up the data
## Copy the data to the bucket
# TODO: Decide on 'copy' or 'move'
# The latter will delete the data from disk on success
## Use pigz for compression
echo "Tarring ${DATA_DIR}..."
tar \
    --use-compress-program="pigz --best --recursive" \
    -cf ${SBID}.tar.gz \
    ${DATA_DIR}

echo "Uploading ${SBID}.tar.gz..."
rclone \
    copy \
    -P \
    ${SBID}.tar.gz \
    ${REMOTE_NAME}:${BUCKET_NAME}/

echo "Removing ${SBID}.tar.gz..."
rm -v ${SBID}.tar.gz

echo "Emitting racs.backup_completed CLINK event..."
# Emit racs.backup_completed CLINK event, with scheduling block payload
clink emit-event --input - <<EOF
{
    "id": "$(uuidgen --random)",
    "source": "clink.cli",
    "specversion": "1.0",
    "subject": "urn:askap:scheduling-block:::scheduling-block/${SBID}",
    "time": "$(date --utc --iso-8601=seconds)",
    "type": "au.csiro.atnf.askap.racs.backup_completed",
    "data": $(askap-tosconnector scheduling-block --format=json "${SBID}")
}
EOF
