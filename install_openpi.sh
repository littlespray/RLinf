wandb login $(cat /lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/rlinf_assets/wandb_ssk.txt)

GIT_LFS_SKIP_SMUDGE=1 uv pip install git+https://github.com/RLinf/openpi
uv pip install transformers==4.53.2
uv pip uninstall pynvml
cp -r /opt/venv/openvla-oft/lib/python3.10/site-packages/openpi/models_pytorch/transformers_replace/* /opt/venv/openvla-oft/lib/python3.10/site-packages/transformers/

mkdir -p /usr/share/glvnd/egl_vendor.d
printf '{\n    "file_format_version" : "1.0.0",\n    "ICD" : {\n        "library_path" : "libEGL_nvidia.so.0"\n    }\n}\n' > /usr/share/glvnd/egl_vendor.d/10_nvidia.json
mkdir -p /etc/vulkan/icd.d
printf '{\n    "file_format_version" : "1.0.0",\n    "ICD" : {\n        "library_path" : "libGLX_nvidia.so.0",\n        "api_version" : "1.3.194"\n    }\n}\n' > /etc/vulkan/icd.d/nvidia_icd.json
export OMNIGIBSON_HEADLESS=1
export ISAAC_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/rlinf_assets/isaac-sim
export OMNIGIBSON_DATA_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/DATASETS/datasets/

export TORCHDYNAMO_DISABLE=1
bash examples/embodiment/run_embodiment.sh behavior_ppo_openpi