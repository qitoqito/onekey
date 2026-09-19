
#!/bin/bash
# 通用安装脚本 - 使用临时目录解压后复制

set -e

# ---------- 配置 ----------
INSTALL_DIR="/ql/data/scripts/qitoqito_psyduck/static/libcurl-impersonate"
#!/bin/bash

# 默认版本（网络失败时使用）
DEFAULT_VERSION="v2.2.2"

# 获取最新版本号的函数
get_latest_version() {
    local latest
    latest=$(curl -s "https://github.com/lexiforest/curl-impersonate/releases" | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 2>/dev/null)
    # 如果仍然失败，使用默认版本
    if [ -z "$latest" ]; then
        echo "⚠️ 无法获取最新版本，使用默认版本: $DEFAULT_VERSION" >&2
        echo "$DEFAULT_VERSION"
    else
        echo "$latest"
    fi
}

# 使用示例
VERSION=$(get_latest_version)
echo "✅ 使用版本: $VERSION"

# 拼接下载 URL
DOWNLOAD_URL="https://github.com/lexiforest/curl-impersonate/releases/download/${VERSION}/libcurl-impersonate-${VERSION}.x86_64-linux-musl.tar.gz"
echo "📥 下载地址: $DOWNLOAD_URL"
BASE_URL="https://github.com/lexiforest/curl-impersonate/releases/download/${VERSION}"

# ---------- 检测架构和 libc ----------
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)       ARCH="x86_64" ;;
    aarch64|arm64)      ARCH="aarch64" ;;
    armv7l|armhf)       ARCH="arm" ;;
    *) echo "❌ 不支持的架构: $ARCH"; exit 1 ;;
esac

if ldd --version 2>&1 | grep -qi "musl"; then
    LIBC="musl"
elif ldd --version 2>&1 | grep -qi "GLIBC"; then
    LIBC="gnu"
else
    if [ -f /etc/os-release ] && grep -qi "alpine" /etc/os-release; then
        LIBC="musl"
    else
        LIBC="gnu"
    fi
fi

if [ "$ARCH" = "arm" ] && [ "$LIBC" = "musl" ]; then
    echo "❌ armv7l + musl 暂无预编译包"
    exit 1
fi

# 组装包名
if [ "$ARCH" = "arm" ]; then
    ARCH_SPEC="arm-linux-gnueabihf"
else
    ARCH_SPEC="${ARCH}-linux-${LIBC}"
fi

PACKAGE_NAME="libcurl-impersonate-${VERSION}.${ARCH_SPEC}.tar.gz"
DOWNLOAD_URL="${BASE_URL}/${PACKAGE_NAME}"

echo "✅ 检测到: ARCH=$ARCH, LIBC=$LIBC"
echo "📥 下载: $DOWNLOAD_URL"

# ---------- 创建临时目录并下载 ----------
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"
wget -q --show-progress "$DOWNLOAD_URL" -O "$PACKAGE_NAME" || {
    echo "❌ 下载失败"
    rm -rf "$TMP_DIR"
    exit 1
}

# ---------- 解压（完整保留结构） ----------
tar -xzf "$PACKAGE_NAME"
rm -f "$PACKAGE_NAME"

# ---------- 查找 libcurl-impersonate.so ----------
SO_FILE=$(find . -name "libcurl-impersonate.so" -type f -o -type l | head -1)
if [ -z "$SO_FILE" ]; then
    echo "❌ 未找到 libcurl-impersonate.so"
    rm -rf "$TMP_DIR"
    exit 1
fi

# ---------- 创建目标目录并复制所有 .so 相关文件 ----------
mkdir -p "$INSTALL_DIR"
# 获取 .so 文件所在目录（可能是 lib/ 或 curl/lib/ 等）
SO_DIR=$(dirname "$SO_FILE")
# 复制该目录下所有 libcurl-impersonate.so* 文件（保留软链接）
cp -P "$SO_DIR"/libcurl-impersonate.so* "$INSTALL_DIR/" 2>/dev/null || {
    echo "❌ 复制失败"
    rm -rf "$TMP_DIR"
    exit 1
}

# 如果复制后没有 libcurl-impersonate.so（只有带版本号的），创建软链接
if [ ! -f "$INSTALL_DIR/libcurl-impersonate.so" ]; then
    # 找到最新的版本文件
    LATEST=$(ls -1 "$INSTALL_DIR"/libcurl-impersonate.so.* 2>/dev/null | sort -V | tail -1)
    if [ -n "$LATEST" ]; then
        ln -sf "$(basename "$LATEST")" "$INSTALL_DIR/libcurl-impersonate.so"
    else
        echo "❌ 无法创建软链接"
        rm -rf "$TMP_DIR"
        exit 1
    fi
fi

# ---------- 清理临时目录 ----------
rm -rf "$TMP_DIR"

# ---------- 验证 ----------
if [ ! -f "$INSTALL_DIR/libcurl-impersonate.so" ]; then
    echo "❌ 安装失败"
    exit 1
fi

echo "✅ 安装成功！库文件位于: $INSTALL_DIR"
ls -l "$INSTALL_DIR"/libcurl-impersonate.so*

export LIBCURL_PATH=/ql/data/scripts/qitoqito_psyduck/static/libcurl-impersonate/libcurl-impersonate.so
cd /ql/data/scripts/qitoqito_psyduck
# ---------- 创建 package.json（如果不存在） ----------
if [ ! -f package.json ]; then
    cat > package.json <<'EOF'
{
  "type": "module",
  "name": "psyduck",
  "version": "1.0.0",
  "keywords": [],
  "author": "",
  "license": "ISC",
  "description": ""
}
EOF
    echo "✅ 已创建 package.json"
else
    echo "⚠️ package.json 已存在，跳过创建"
fi
pnpm install impers@latest
cat > fingerPrint.js <<'EOF'
import * as impers from "impers";
let kkk = {
    'akamai_fingerprint': '2:0;3:100;4:2097152;9:1|10420225|0|m,s,a,p',
    'akamai_fingerprint_hash': 'c52879e43202aeb92740be6e8c86ea96',
    'ja3': '771,4866-4867-4865-49196-49195-52393-49200-49199-52392-49162-49161-49172-49171-157-156-53-47-49160-49170-10,0-23-65281-10-11-16-5-13-18-51-45-43-27,4588-29-23-24-25,0',
    'ja3_hash': 'ecdf4f49dd59effc439639da29186671'
}
let ja3 = kkk.ja3
let akamai = kkk.akamai_fingerprint
let ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/8.0.33(0x18002129) NetType/WIFI Language/zh_CN"
let maxRedirects = 1
let r4 = await impers.get("https://get.ja3.zone", {
    httpVersion: '2',
    akamai: '2:0;3:100;4:2097152;9:1|10420225|0|m,s,a,p',
    ja3: '771,4865-4866-4867-49196-49195-52393-49200-49199-52392-49162-49161-49172-49171-157-156-53-47-49160-49170-10,0-23-65281-10-11-16-5-13-18-51-45-43-27-21,29-23-24-25,0',
    impersonate: 'safari_ios',
    method: 'GET',
    headers: {
        'user-agent': 'jdapp;iPhone;15.9.30;;;M/5.0;appBuild/169952;jdSupportDarkMode/0;lang/zh_CN;site/CN;elder/0;ef/1;ep/%7B%22ciphertype%22%3A5%2C%22cipher%22%3A%7B%22ud%22%3A%22Ctc4EWO2EJLrDJG5ZQDvDtDuYJc3ZtSyZwS4ZNrwYJu1ENDtDzOzDG%3D%3D%22%2C%22sv%22%3A%22CJCkCs4n%22%2C%22iad%22%3A%22%22%7D%2C%22ts%22%3A1788494621%2C%22hdid%22%3A%22JM9F1ywUPwflvMIpYPok0tt5k9kW4ArJEU3lfLhxBqw%3D%22%2C%22version%22%3A%221.0.3%22%2C%22appname%22%3A%22com.360buy.jdmobile%22%2C%22ridx%22%3A-1%7D;Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148;supportJDSHWK/1;',
        referer: 'https://prodev.m.jd.com/',
    },
    timeout: 5,
    maxRedirects,
    count: 0
});
console.log("指纹信息:",JSON.stringify({
    'akamai_fingerprint': akamai,
    'akamai_fingerprint_hash': r4.json().http2.akamai_fingerprint_hash,
    'ja3': ja3,
    'ja3_hash': r4.json().tls.ja3_hash,
}))
EOF
# ---------- 运行测试并判断 ----------
echo "正在执行指纹测试，如果正常输出 ja3 等信息，则保留模块..."

# 运行测试，捕获输出和退出码
OUTPUT=$(node fingerPrint.js 2>&1)
EXIT_CODE=$?

# 判断是否成功：输出包含 "ja3_hash:" 且退出码为 0
if echo "$OUTPUT" | grep -q "ja3_hash" && [ $EXIT_CODE -eq 0 ]; then
    echo "输出内容："
    echo "$OUTPUT"
else
    echo "❌ 测试失败，测试模块将被卸载。"
    echo "错误输出："
    echo "$OUTPUT"
    # 卸载 impers
    pnpm uninstall impers
    echo "已卸载 impers。"
fi

echo "--------------------------------------------------"
echo "如果上面正常输出，请正确添加环境变量："
echo "export LIBCURL_PATH=${INSTALL_DIR}/libcurl-impersonate.so"
echo "--------------------------------------------------"
