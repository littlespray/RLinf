#!/bin/bash
#SBATCH --job-name=rlinf_1p
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:2
#SBATCH --time=168:00:00
#SBATCH --partition=gpu_nodes_all
#SBATCH --account=general_cs_infra
#SBATCH --output=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/outputs/rlinf_outputs/rlinf_1p_%j.out
#SBATCH --error=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/outputs/rlinf_outputs/rlinf_1p_%j.err
#SBATCH --requeue


ROOT_DIR=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/RLinf

mkdir -p /lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/outputs/rlinf_outputs

CACHE_ID=${SLURM_JOB_ID:-$(date +%Y%m%d-%H%M%S)}
CACHE_DIR=/lustre/fs1/portfolios/general/users/maxzhaoshuol/all_texturecache/${CACHE_ID}
mkdir -p "${CACHE_DIR}"

CONTAINER_IMAGE=/lustre/fs1/portfolios/general/users/maxzhaoshuol/docker/rlinf_b1k.sqsh
CONTAINER_MOUNTS="${CACHE_DIR}:/root/.cache/ov:rw,/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior:/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior:rw,/home/maxzhaoshuol:/home/maxzhaoshuol:rw"
CONTAINER_WORKDIR=${ROOT_DIR}

srun \
  --ntasks=1 \
  --ntasks-per-node=1 \
  --container-image=${CONTAINER_IMAGE} \
  --container-mounts=${CONTAINER_MOUNTS} \
  --container-workdir=${CONTAINER_WORKDIR} \
  --no-container-mount-home \
  bash -lc "
    # Setup EGL and Vulkan
    mkdir -p /usr/share/glvnd/egl_vendor.d
    cat <<'EOF' > /usr/share/glvnd/egl_vendor.d/10_nvidia.json
{
    \"file_format_version\" : \"1.0.0\",
    \"ICD\" : {
        \"library_path\" : \"libEGL_nvidia.so.0\"
    }
}
EOF

    mkdir -p /etc/vulkan/icd.d
    cat <<'EOF' > /etc/vulkan/icd.d/nvidia_icd.json
{
    \"file_format_version\" : \"1.0.0\",
    \"ICD\" : {
        \"library_path\" : \"libGLX_nvidia.so.0\",
        \"api_version\" : \"1.3.194\"
    }
}
EOF

    sleep infinity
  "
