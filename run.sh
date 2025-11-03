export ISAAC_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/rlinf_assets/isaac-sim
export OMNIGIBSON_DATA_PATH=/lustre/fs1/portfolios/general/users/maxzhaoshuol/behavior/DATASETS/datasets/
export OMNIGIBSON_HEADLESS=1

source switch_env openvla-oft
bash examples/embodiment/run_embodiment.sh behavior_ppo_openvlaoft