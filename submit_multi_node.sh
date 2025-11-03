#!/bin/bash
#SBATCH --job-name=rlinf_multi_node
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:4
#SBATCH --time=168:00:00
#SBATCH --partition=gpu_nodes_all
#SBATCH --account=general_cs_infra
#SBATCH --output=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/outputs/rlinf_outputs/rlinf_multi_node_%j.out
#SBATCH --error=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/outputs/rlinf_outputs/rlinf_multi_node_%j.err
#SBATCH --requeue

set -euo pipefail

ROOT_DIR=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/RLinf
HEAD_FILE=${ROOT_DIR}/ray_utils/ray_head_ip.txt
rm -f "${HEAD_FILE}"

mkdir -p /lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/outputs

CACHE_ID=${SLURM_JOB_ID:-$(date +%Y%m%d-%H%M%S)}
CACHE_DIR=/lustre/fs1/portfolios/general/users/maxzhaoshuol/all_texturecache/${CACHE_ID}
mkdir -p "${CACHE_DIR}"

CONTAINER_IMAGE=/lustre/fs1/portfolios/general/users/maxzhaoshuol/docker/rlinf_b1k.sqsh
CONTAINER_MOUNTS="${CACHE_DIR}:/root/.cache/ov:rw,/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior:/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior:rw,/home/maxzhaoshuol:/home/maxzhaoshuol:rw"
CONTAINER_WORKDIR=${ROOT_DIR}

HEAD_NODE=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
echo "Head node: ${HEAD_NODE}"

# Start Ray on every node
srun \
  --ntasks=${SLURM_NNODES} \
  --ntasks-per-node=1 \
  --container-image=${CONTAINER_IMAGE} \
  --container-mounts=${CONTAINER_MOUNTS} \
  --container-workdir=${CONTAINER_WORKDIR} \
  --no-container-mount-home \
  bash -lc "
    source switch_env openvla-oft
    uv pip install --quiet 'click<8.1'
    uv pip install 'pydantic>=1.10.0,<2.0.0'
    ray stop

    sleep 10

    RANK=\${SLURM_PROCID} bash ray_utils/start_ray.sh
    wandb login \$(cat /lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/rlinf_assets/wandb_ssk.txt)
    export ISAAC_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/rlinf_assets/isaac-sim
    export OMNIGIBSON_DATA_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/DATASETS/datasets/
    export OMNIGIBSON_HEADLESS=1

    if [[ \${SLURM_PROCID} -eq 0 ]]; then
      bash ray_utils/check_ray.sh 16
      bash examples/embodiment/run_embodiment.sh multi_node
    fi
    sleep 60
  "
