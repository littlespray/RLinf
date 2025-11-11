CACHE_ID=${SLURM_JOB_ID:-$(date +%Y%m%d-%H%M%S)}
CACHE_DIR=/lustre/fs1/portfolios/general/users/maxzhaoshuol/all_texturecache/${CACHE_ID}
mkdir -p "${CACHE_DIR}"

srun \
  --account general_cs_infra \
  --partition gpu_nodes_all \
  --time 168:00:00 \
  --gpus-per-node 4 \
  --nodes 1 \
  --pty \
  --container-image /lustre/fs1/portfolios/general/users/maxzhaoshuol/docker/rlinf_b1k.sqsh \
  --container-mounts "\
${CACHE_DIR}:/root/.cache/ov:rw,\
/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior:/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior:rw,\
/home/maxzhaoshuol:/home/maxzhaoshuol:rw" \
  --container-workdir /lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/RLinf \
  --no-container-mount-home \
  /bin/bash