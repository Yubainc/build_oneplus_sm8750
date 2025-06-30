#!/bin/bash

# 反调试保护
if [ -n "$STRACE" ] || [ -n "$GDB" ]; then
  echo "调试尝试被阻止"
  exit 1
fi

# 检查常见调试工具
if ps aux | grep -E 'strace|gdb|ltrace'; then
  echo "检测到调试工具"
  exit 1
fi

cd kernel_workspace/kernel_platform
curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/susfs-main/kernel/setup.sh" | bash -s susfs-main
cd ./KernelSU

for i in {1..3}; do
  KSU_API_VERSION=$(curl -s "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/susfs-main/kernel/Makefile" | 
    grep -m1 "KSU_VERSION_API :=" | 
    awk -F'= ' '{print $2}' | 
    tr -d '[:space:]')
  [ -n "$KSU_API_VERSION" ] && break || sleep 2
done

[ -z "$KSU_API_VERSION" ] && KSU_API_VERSION="3.1.6"
echo "KSU_API_VERSION=$KSU_API_VERSION" >> $GITHUB_ENV

ENCODED_SUFFIX="VEdAcWR5a2VybmVs"
DECODED_SUFFIX=$(echo "$ENCODED_SUFFIX" | base64 -d)

VERSION_DEFINITIONS=$(cat << EOF
define get_ksu_version_full
v\\$1-$DECODED_SUFFIX
endef
KSU_VERSION_API := $KSU_API_VERSION
KSU_VERSION_FULL := v$KSU_API_VERSION-$DECODED_SUFFIX
EOF
)

sed -i '/define get_ksu_version_full/,/endef/d' kernel/Makefile
sed -i '/KSU_VERSION_API :=/d' kernel/Makefile
sed -i '/KSU_VERSION_FULL :=/d' kernel/Makefile

awk -v def="$VERSION_DEFINITIONS" '
  /REPO_OWNER :=/ {print; print def; inserted=1; next}
  1
  END {if (!inserted) print def}
' kernel/Makefile > kernel/Makefile.tmp && mv kernel/Makefile.tmp kernel/Makefile

KSU_VERSION=$(expr $(git rev-list --count main) + 10700 2>/dev/null || echo 13000)
echo "KSUVER=$KSU_VERSION" >> $GITHUB_ENV

grep -A10 "REPO_OWNER" kernel/Makefile
grep "KSU_VERSION_FULL" kernel/Makefile

