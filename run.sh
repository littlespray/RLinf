export ISAAC_PATH=/workspace/isaac-sim
export OMNIGIBSON_DATA_PATH=/opt/BEHAVIOR-1K/datasets
export OMNIGIBSON_HEADLESS=1

# # Disable Ray Tracing and advanced GPU features
# export OMNI_KIT_RENDERER_ENABLED=0
# export OMNI_KIT_RAYTRACING_ENABLED=0
# export RTX_ENABLED=0
# export RENDER_MODE=offscreen

# # 强制使用 OpenGL 而不是 Vulkan
# export CARB_GRAPHICS_PREFERRED_API=opengl
# export CARB_GRAPHICS_VULKAN_ENABLED=0
# export OMNIGIBSON_RENDER_DEVICE=opengl  # ← 您的 run.sh 缺少这个

# # 禁用 XR 扩展加载
# export OMNI_KIT_DISABLE_XR=1  # ← 您的 run.sh 缺少这个
# export CARB_APP_DISABLE_EXTENSIONS="omni.kit.xr.core"  # ← 缺少

# # 其他防崩溃设置
# export CARB_GRAPHICS_MGPU_ENABLED=0
# export __GL_SYNC_TO_VBLANK=0
# export __GLX_VENDOR_LIBRARY_NAME=nvidia

source switch_env openvla-oft
bash examples/embodiment/run_embodiment.sh behavior_ppo_openvlaoft
