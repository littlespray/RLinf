#!/bin/bash

echo "Starting interactive debug session with 4 GPUs..."

# ---- Discover host driver locations ----
DRVLIB="$(ldconfig -p | awk '/libnvidia-ngx\.so\.1/{print $NF; exit}' | xargs -r dirname)"
ICDJSON="$(find /cm/local/apps /usr/share /etc -maxdepth 6 -name 'nvidia_icd.json' 2>/dev/null | head -n1 || true)"
ICDDIR="$(dirname "${ICDJSON}")"
ICDBASE="$(basename "${ICDJSON}")"

# Create cache directory
CACHE_DIR="/lustre/fs1/portfolios/general/users/maxzhaoshuol/all_texturecache/debug_$$"
mkdir -p ${CACHE_DIR}

# Get interactive shell in container
srun --nodes=1 \
  --ntasks-per-node=1 \
  --gres=gpu:4 \
  --time=02:00:00 \
  --partition=gpu_nodes_all \
  --account=general_cs_infra \
  --pty \
  --container-image=/lustre/fs1/portfolios/general/users/maxzhaoshuol/docker/rlinf_b1k.sqsh \
  --container-mounts=/lustre/fs1/portfolios/general/users/maxzhaoshuol/imaginaire4:/lustre/fs1/portfolios/general/users/maxzhaoshuol/imaginaire4:rw,/lustre/fs1/portfolios/general/users/maxzhaoshuol/logs:/lustre/fs1/portfolios/general/users/maxzhaoshuol/logs:rw,/lustre/fs1/portfolios/general/users:/lustre/fs1/portfolios/general/users:rw,${DRVLIB}:/opt/host_driver/lib64:ro,${ICDDIR}:/opt/host_driver/icd.d:ro,/usr/bin/nvidia-smi:/usr/bin/nvidia-smi:ro,${CACHE_DIR}:/root/.cache/ov:rw,/home/maxzhaoshuol:/home/maxzhaoshuol:rw \
  --export=ALL,NVIDIA_VISIBLE_DEVICES=all,NVIDIA_DRIVER_CAPABILITIES=graphics,compute,utility,display \
  --container-env=LD_LIBRARY_PATH=/opt/host_driver/lib64:/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64 \
  --container-env=VK_ICD_FILENAMES=/opt/host_driver/icd.d/${ICDBASE} \
  bash -lc "
    # Set up environment
    export LD_LIBRARY_PATH=/opt/host_driver/lib64:/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:\$LD_LIBRARY_PATH
    echo /opt/host_driver/lib64 > /etc/ld.so.conf.d/host-nvidia.conf
    ldconfig
    
    # Set RLinf environment variables
    export ISAAC_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/rlinf_assets/isaac-sim
    export OMNIGIBSON_DATA_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/DATASETS/datasets/
    export OMNIGIBSON_HEADLESS=1
    export HF_DATASETS_CACHE=/lustre/fs1/portfolios/general/users/maxzhaoshuol/huggingface_cache/
    
    # Change to RLinf directory
    cd /lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/RLinf
    
    echo '========================================='
    echo 'Interactive debug session started!'
    echo 'You are now inside the container.'
    echo ''
    echo 'To test GPU access:'
    echo '  nvidia-smi'
    echo ''
    echo 'To switch environment:'
    echo '  source switch_env openvla-oft'
    echo ''
    echo 'To run training:'
    echo '  bash examples/embodiment/run_embodiment.sh behavior_ppo_openvlaoft'
    echo '========================================='
    echo ''
    
    # Start interactive bash
    exec bash
  "
