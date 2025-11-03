CACHE_ID=${SLURM_JOB_ID:-$(date +%Y%m%d-%H%M%S)}
CACHE_DIR=/lustre/fs1/portfolios/general/users/maxzhaoshuol/all_texturecache/${CACHE_ID}
mkdir -p "${CACHE_DIR}"

srun \
  --account general_cs_infra \
  --partition gpu_nodes_all \
  --time 168:00:00 \
  --gpus 4 \
  --pty \
  --container-image /lustre/fs1/portfolios/general/users/maxzhaoshuol/docker/rlinf_b1k.sqsh \
  --container-mounts "\
${CACHE_DIR}:/root/.cache/ov:rw,\
/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior:/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior:rw,\
/home/maxzhaoshuol:/home/maxzhaoshuol:rw" \
  --container-workdir /lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/RLinf \
  --no-container-mount-home \
  /bin/bash
#   bash -lc "
#     mkdir -p /usr/share/glvnd/egl_vendor.d
#     printf '{\n    "file_format_version" : "1.0.0",\n    "ICD" : {\n        "library_path" : "libEGL_nvidia.so.0"\n    }\n}\n' > /usr/share/glvnd/egl_vendor.d/10_nvidia.json
#     mkdir -p /etc/vulkan/icd.d
#     printf '{\n    "file_format_version" : "1.0.0",\n    "ICD" : {\n        "library_path" : "libGLX_nvidia.so.0",\n        "api_version" : "1.3.194"\n    }\n}\n' > /etc/vulkan/icd.d/nvidia_icd.json
#     # Set RLinf environment variables
#     export ISAAC_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/rlinf_assets/isaac-sim
#     export OMNIGIBSON_DATA_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/DATASETS/datasets/
#     export OMNIGIBSON_HEADLESS=1
#     source switch_env openvla-oft
#     uv pip install 'pydantic>=1.10.0,<2.0.0'

#     wandb login $(cat /lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/rlinf_assets/wandb_ssk.txt)

#     # Change to RLinf directory
#     cd /lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/RLinf
#     bash examples/embodiment/run_embodiment.sh behavior_ppo_openvlaoft
# "