#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:4
#SBATCH --time=8:00:00
#SBATCH --time-min=8:00:00
#SBATCH --partition=gpu_nodes_all
#SBATCH --account=general_cs_infra
#SBATCH --exclude=
#SBATCH --requeue
#SBATCH --job-name=rlinf_train_8gpu
#SBATCH --output=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/outputs/rlinf_train_%j.out

export MASTER_PORT=$(expr 10000 + $(echo -n $SLURM_JOBID | tail -c 4))
export WORLD_SIZE=$(($SLURM_NNODES * $SLURM_NTASKS_PER_NODE))
export MASTER_ADDR=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export SLURM_LOG_DIR=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/outputs/rlinf_outputs/

echo "SLURM_JOB_ID="$SLURM_JOB_ID
echo "MASTER_PORT="$MASTER_PORT
echo "WORLD_SIZE="$WORLD_SIZE
echo "MASTER_ADDR="$MASTER_ADDR
echo "Using GPUs: "$CUDA_VISIBLE_DEVICES

# ---- Discover host driver locations on the allocated node ----
DRVLIB="$(ldconfig -p | awk '/libnvidia-ngx\.so\.1/{print $NF; exit}' | xargs -r dirname)"
if [[ -z "${DRVLIB}" || ! -r "${DRVLIB}/libnvidia-ngx.so.1" || ! -r "${DRVLIB}/libGLX_nvidia.so.0" ]]; then
  echo "ERROR: Could not find host driver libs (NGX/GLX) on this node." >&2
  ldconfig -p | egrep 'libnvidia-ngx\.so\.1|libGLX_nvidia\.so\.0' || true
  exit 1
fi

if [[ -f /usr/share/vulkan/icd.d/nvidia_icd.json ]]; then
  ICDJSON="/usr/share/vulkan/icd.d/nvidia_icd.json"
else
  ICDJSON="$(find /cm/local/apps /usr/share /etc -maxdepth 6 -name 'nvidia_icd.json' 2>/dev/null | head -n1 || true)"
fi
if [[ -z "${ICDJSON}" || ! -r "${ICDJSON}" ]]; then
  echo "ERROR: Could not find Vulkan ICD JSON (nvidia_icd.json) on this node." >&2
  exit 1
fi
ICDDIR="$(dirname "${ICDJSON}")"
ICDBASE="$(basename "${ICDJSON}")"

echo "DRVLIB=${DRVLIB}"
echo "ICDJSON=${ICDJSON}"

# Create cache directories
mkdir -p /lustre/fs1/portfolios/general/users/maxzhaoshuol/all_texturecache/${SLURM_JOB_ID}
mkdir -p ${SLURM_LOG_DIR}

# Route huggingface cache dir
export HF_DATASETS_CACHE=/lustre/fs1/portfolios/general/users/maxzhaoshuol/huggingface_cache/

# Run training in container
srun -o ${SLURM_LOG_DIR}/train_%j.log \
  --container-image=/lustre/fs1/portfolios/general/users/maxzhaoshuol/docker/rlinf_b1k.sqsh \
  --container-mounts=/lustre/fs1/portfolios/general/users/maxzhaoshuol/imaginaire4:/lustre/fs1/portfolios/general/users/maxzhaoshuol/imaginaire4:rw,/lustre/fs1/portfolios/general/users/maxzhaoshuol/logs:/lustre/fs1/portfolios/general/users/maxzhaoshuol/logs:rw,/lustre/fs1/portfolios/general/users:/lustre/fs1/portfolios/general/users:rw,${DRVLIB}:/opt/host_driver/lib64:ro,${ICDDIR}:/opt/host_driver/icd.d:ro,/usr/bin/nvidia-smi:/usr/bin/nvidia-smi:ro,/lustre/fs1/portfolios/general/users/maxzhaoshuol/all_texturecache/${SLURM_JOB_ID}:/root/.cache/ov:rw,/home/maxzhaoshuol:/home/maxzhaoshuol:rw \
  --export=ALL,NVIDIA_VISIBLE_DEVICES=all,NVIDIA_DRIVER_CAPABILITIES=graphics,compute,utility,display \
  --container-env=LD_LIBRARY_PATH=/opt/host_driver/lib64:/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64 \
  --container-env=VK_ICD_FILENAMES=/opt/host_driver/icd.d/${ICDBASE} \
  bash -lc """
    # Belt & suspenders: set inside the container shell too.
    export LD_LIBRARY_PATH=/opt/host_driver/lib64:/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:\$LD_LIBRARY_PATH
    
    # Update ldconfig cache to include host driver libraries
    echo /opt/host_driver/lib64 > /etc/ld.so.conf.d/host-nvidia.conf
    ldconfig
    
    # Now this should work inside the container:
    ldconfig -p | egrep \"libnvidia-(ngx|vulkan)\"
    
    # These should exist:
    ls -l /opt/host_driver/lib64/libGLX_nvidia.so.0
    ls -l /opt/host_driver/lib64/libnvidia-ngx.so.1


    echo "CUDA_VISIBLE_DEVICES="\$CUDA_VISIBLE_DEVICES

    # Start tmux session for debugging
    echo "Starting tmux session for debugging"
    mkdir -p /tmp/tmux-47741

    echo "Creating tmux session"
    tmux new-session -d -s debug_\${SLURM_JOB_ID}
    
    echo "Debug tmux session started. You can SSH to the node and run:"
    echo "tmux attach -t debug_\${SLURM_JOB_ID}"

    # Change to RLinf directory
    cd /lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/RLinf

    # Set environment variables from run.sh
    export ISAAC_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/rlinf_assets/isaac-sim
    export OMNIGIBSON_DATA_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/DATASETS/datasets/
    export OMNIGIBSON_HEADLESS=1

    source switch_env openvla-oft

    bash examples/embodiment/run_embodiment.sh behavior_ppo_openvlaoft

    sleep 3600
  """
