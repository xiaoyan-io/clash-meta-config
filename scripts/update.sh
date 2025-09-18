#!/bin/bash
# 自动生成 Clash.Meta 配置脚本

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$BASE_DIR/scripts"
OUTPUT_DIR="$BASE_DIR/output"
HISTORY_DIR="$OUTPUT_DIR/history"
DATE_TAG=$(date +%Y-%m-%d-%H%M)

FINAL_CONFIG="$OUTPUT_DIR/config.yaml"
TEMP_CONFIG="$OUTPUT_DIR/tmp_config.yaml"
NODES_FILE="$OUTPUT_DIR/nodes.yaml"

SUBSCRIBE_URLS=(
  "https://node.freeclashnode.com/uploads/$(date +%Y)/$(date +%m)/1-$(date +%Y%m%d).yaml"
  "https://raw.githubusercontent.com/free-clash-v2ray/free-clash-v2ray.github.io/main/uploads/$(date +%Y)/$(date +%m)/1-$(date +%Y%m%d).yaml"
)

mkdir -p "$OUTPUT_DIR" "$HISTORY_DIR"

echo "=== [1/4] 下载订阅节点 ==="
success=false
for url in "${SUBSCRIBE_URLS[@]}"; do
  echo "尝试获取: $url"
  if curl -sL --max-time 20 "$url" -o "$NODES_FILE"; then
    echo "✅ 成功获取节点: $url"
    success=true
    break
  else
    echo "⚠️ 获取失败，尝试下一个源..."
  fi
done

if [ "$success" = false ]; then
  echo "❌ 所有订阅源获取失败，退出。"
  exit 1
fi

echo "=== [2/4] 生成基础配置 ==="
cat "$SCRIPT_DIR/base.yaml" > "$TEMP_CONFIG"

echo -e "\n# ================= 节点列表 =================" >> "$TEMP_CONFIG"
if grep -q "proxies:" "$NODES_FILE"; then
  grep -A 999 "proxies:" "$NODES_FILE" >> "$TEMP_CONFIG"
else
  echo "⚠️ 订阅文件中未找到 proxies:，请检查订阅格式"
fi

echo "=== [3/4] 合并分组与规则 ==="
echo -e "\n" >> "$TEMP_CONFIG"
cat "$SCRIPT_DIR/groups.yaml" >> "$TEMP_CONFIG"
echo -e "\n" >> "$TEMP_CONFIG"
cat "$SCRIPT_DIR/rules.yaml" >> "$TEMP_CONFIG"

echo "=== [4/4] 输出配置文件 ==="
mv "$TEMP_CONFIG" "$FINAL_CONFIG"
cp "$FINAL_CONFIG" "$HISTORY_DIR/config-$DATE_TAG.yaml"

echo "✅ Clash.Meta 配置生成完成: $FINAL_CONFIG"
echo "📦 历史版本已保存到: $HISTORY_DIR/config-$DATE_TAG.yaml"
