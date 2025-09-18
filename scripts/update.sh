#!/bin/bash
# ===========================================
# Clash.Meta 自动更新配置脚本
# 1. 合并 base.yaml + 订阅节点 + groups.yaml + rules.yaml
# 2. 自动保存历史版本
# 3. 日志输出 & 错误校验
# ===========================================

set -e
WORKDIR=$(dirname "$0")/..
OUTDIR="$WORKDIR/output"
OUTFILE="$OUTDIR/config.yaml"
HISTORY_DIR="$OUTDIR/history"
LOGFILE="$OUTDIR/update.log"

mkdir -p "$OUTDIR" "$HISTORY_DIR"

echo "=============================" | tee -a "$LOGFILE"
echo "开始生成 Clash.Meta 配置: $(date)" | tee -a "$LOGFILE"

# 1. 写入基础配置
cat "$WORKDIR/scripts/base.yaml" > "$OUTFILE"
echo "[OK] 基础配置写入完成" | tee -a "$LOGFILE"

# 2. 下载订阅节点
SUBSCRIBE_URLS=(
  "https://node.freeclashnode.com/uploads/2025/09/1-$(date +%Y%m%d).yaml"
  "https://raw.githubusercontent.com/free-clash-v2ray/free-clash-v2ray.github.io/main/uploads/$(date +%Y)/$(date +%m)/1-$(date +%Y%m%d).yaml"
)

FOUND=0
for url in "${SUBSCRIBE_URLS[@]}"; do
  echo "尝试下载订阅: $url" | tee -a "$LOGFILE"
  if curl -sL "$url" -o /tmp/nodes.yaml && [ -s /tmp/nodes.yaml ]; then
    echo "[OK] 成功下载: $url" | tee -a "$LOGFILE"
    FOUND=1
    break
  else
    echo "[WARN] 下载失败: $url" | tee -a "$LOGFILE"
  fi
done

if [ $FOUND -eq 0 ]; then
  echo "[ERROR] 所有订阅源都下载失败" | tee -a "$LOGFILE"
  exit 1
fi

# 3. 插入节点
if grep -q "^proxies:" /tmp/nodes.yaml; then
  grep -A 999 "proxies:" /tmp/nodes.yaml >> "$OUTFILE"
  echo "[OK] 节点写入完成" | tee -a "$LOGFILE"
else
  echo "[ERROR] 节点文件不包含 proxies 字段" | tee -a "$LOGFILE"
  exit 1
fi

# 4. 写入分组
cat "$WORKDIR/scripts/groups.yaml" >> "$OUTFILE"
echo "[OK] 分组写入完成" | tee -a "$LOGFILE"

# 5. 写入规则
cat "$WORKDIR/scripts/rules.yaml" >> "$OUTFILE"
echo "[OK] 规则写入完成" | tee -a "$LOGFILE"

# 6. 校验文件格式
if ! grep -q "^rules:" "$OUTFILE"; then
  echo "[ERROR] 最终配置缺少 rules 字段" | tee -a "$LOGFILE"
  exit 1
fi

if ! grep -q "^proxy-groups:" "$OUTFILE"; then
  echo "[ERROR] 最终配置缺少 proxy-groups 字段" | tee -a "$LOGFILE"
  exit 1
fi

echo "[OK] 配置文件基本校验通过" | tee -a "$LOGFILE"

# 7. 备份历史版本
cp "$OUTFILE" "$HISTORY_DIR/config_$(date +%Y%m%d_%H%M%S).yaml"
echo "[OK] 历史版本已保存到 $HISTORY_DIR" | tee -a "$LOGFILE"

echo "完成 ✅ 最终配置输出到: $OUTFILE" | tee -a "$LOGFILE"
echo "=============================" | tee -a "$LOGFILE"
