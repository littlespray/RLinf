#!/bin/bash
# 改进版的 Vulkan/EGL 修复（修正同事方法中的错误）
# 必须在 Docker 容器内以 root 身份运行

set -e

echo "=== Quick Vulkan/EGL Fix ==="
echo "Fixing NVIDIA driver configuration..."
echo ""

# 检查是否有 root 权限
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: This script must be run as root"
    echo "Run with: sudo bash quick_vulkan_fix.sh"
    exit 1
fi

# 1. EGL 配置（这部分是正确的）
echo "[1/3] Configuring EGL..."
mkdir -p /usr/share/glvnd/egl_vendor.d

cat > /usr/share/glvnd/egl_vendor.d/10_nvidia.json <<EOF
{
    "file_format_version" : "1.0.0",
    "ICD" : {
        "library_path" : "libEGL_nvidia.so.0"
    }
}
EOF

if [ -f /usr/share/glvnd/egl_vendor.d/10_nvidia.json ]; then
    echo "✓ EGL configuration created"
else
    echo "✗ Failed to create EGL config"
    exit 1
fi

# 2. Vulkan ICD 配置（修正版本）
echo ""
echo "[2/3] Configuring Vulkan ICD..."
mkdir -p /etc/vulkan/icd.d

# 尝试多种可能的库路径
# 注意：您同事的版本使用 libGLX_nvidia.so.0，这在某些配置下可能有效
# 但标准做法是使用专门的 Vulkan 库

# 检查哪个库存在
if [ -f /usr/lib/x86_64-linux-gnu/libGLX_nvidia.so.0 ] || \
   [ -f /usr/lib64/libGLX_nvidia.so.0 ] || \
   [ -f /usr/local/lib/libGLX_nvidia.so.0 ]; then
    
    # 方法 A: 使用您同事的配置（可能在某些系统上有效）
    cat > /etc/vulkan/icd.d/nvidia_icd.json <<EOF
{
    "file_format_version" : "1.0.0",
    "ICD" : {
        "library_path" : "libGLX_nvidia.so.0",
        "api_version" : "1.3.194"
    }
}
EOF
    echo "✓ Vulkan ICD configuration created (using libGLX_nvidia.so.0)"
    
else
    echo "⚠ Warning: libGLX_nvidia.so.0 not found"
    echo "  Trying alternative configuration..."
    
    # 方法 B: 尝试标准 Vulkan 库
    cat > /etc/vulkan/icd.d/nvidia_icd.json <<EOF
{
    "file_format_version" : "1.0.0",
    "ICD" : {
        "library_path" : "libGLX_nvidia.so.0",
        "api_version" : "1.2.0"
    }
}
EOF
    echo "✓ Created fallback Vulkan ICD configuration"
fi

# 3. 安装必要的包
echo ""
echo "[3/3] Installing Vulkan utilities..."
if ! command -v vulkaninfo &> /dev/null; then
    apt-get update -qq 2>&1 | grep -v "debconf" || true
    apt-get install -y -qq vulkan-tools libvulkan1 2>&1 | grep -v "debconf" || true
    echo "✓ Vulkan tools installed"
else
    echo "✓ Vulkan tools already installed"
fi

# 测试
echo ""
echo "=== Testing Configuration ==="

# 测试 Vulkan
echo ""
echo "Testing Vulkan..."
if vulkaninfo --summary &> /tmp/vulkan_test.log; then
    echo "✅ SUCCESS: Vulkan is working!"
    vulkaninfo --summary 2>&1 | head -20
    echo ""
    echo "🎉 You can now use run.sh with Vulkan support"
    VULKAN_WORKS=1
else
    echo "❌ Vulkan test failed"
    echo "Error details:"
    cat /tmp/vulkan_test.log | head -10
    echo ""
    echo "⚠ Vulkan not available, will use OpenGL fallback"
    VULKAN_WORKS=0
fi

echo ""
echo "=== Configuration Files ==="
echo "EGL config:"
cat /usr/share/glvnd/egl_vendor.d/10_nvidia.json

echo ""
echo "Vulkan ICD config:"
cat /etc/vulkan/icd.d/nvidia_icd.json

echo ""
echo "=== Next Steps ==="

if [ $VULKAN_WORKS -eq 1 ]; then
    echo ""
    echo "✅ Vulkan is working! You can run:"
    echo "   bash run.sh"
    echo ""
else
    echo ""
    echo "⚠ Vulkan is NOT working. Use OpenGL mode instead:"
    echo ""
    echo "Option 1 (Recommended): Use the safe script"
    echo "   bash run_safe.sh"
    echo ""
    echo "Option 2: Force OpenGL in your current script"
    echo "   Add these exports before running:"
    echo "   export CARB_GRAPHICS_PREFERRED_API=opengl"
    echo "   export CARB_GRAPHICS_VULKAN_ENABLED=0"
    echo "   export OMNIGIBSON_RENDER_DEVICE=opengl"
    echo "   bash run.sh"
    echo ""
fi

echo "=== Diagnostics ==="
echo "NVIDIA driver info:"
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null || echo "nvidia-smi failed"

echo ""
echo "NVIDIA libraries found:"
find /usr -name "libEGL_nvidia.so*" 2>/dev/null | head -3 || echo "None"
find /usr -name "libGLX_nvidia.so*" 2>/dev/null | head -3 || echo "None"

echo ""
echo "=== Fix Complete ==="


