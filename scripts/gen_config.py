import yaml, requests, datetime

# ======================
# 订阅链接（可修改/添加）
# ======================
SUB_URLS = [
    "https://node.freeclashnode.com/uploads/2025/09/1-{}.yaml".format(datetime.datetime.now().strftime("%Y%m%d")),
    "https://raw.githubusercontent.com/free-clash-v2ray/free-clash-v2ray.github.io/main/uploads/{}/1-{}.yaml".format(
        datetime.datetime.now().strftime("%Y/%m"), datetime.datetime.now().strftime("%Y%m%d")
    )
]

OUTFILE = "clash-meta-config.yaml"
BASE_FILE = "config/base.yaml"

# ======================
# 下载订阅
# ======================
nodes = None
for url in SUB_URLS:
    try:
        print(f"尝试下载: {url}")
        r = requests.get(url, timeout=15)
        if r.status_code == 200 and "proxies:" in r.text:
            nodes = yaml.safe_load(r.text)
            print(f"✅ 成功: {url}")
            break
    except Exception as e:
        print(f"⚠️ 失败: {url} -> {e}")

if nodes is None:
    raise SystemExit("❌ 所有订阅获取失败")

proxy_names = [p["name"] for p in nodes.get("proxies", [])]
print(f"共获取 {len(proxy_names)} 个节点")

# ======================
# 加载基础配置
# ======================
with open(BASE_FILE, "r", encoding="utf-8") as f:
    config = yaml.safe_load(f)

# ======================
# 写入节点
# ======================
config["proxies"] = nodes.get("proxies", [])

# ======================
# 写入分组
# ======================
groups = [
    {"name": "🚀 自动选择", "type": "url-test", "url": "http://www.gstatic.com/generate_204", "interval": 600, "tolerance": 150, "proxies": proxy_names},
    {"name": "📱 社交媒体", "type": "select", "proxies": proxy_names},
    {"name": "🎥 视频媒体", "type": "select", "proxies": proxy_names},
    {"name": "🎮 游戏加速", "type": "select", "proxies": proxy_names},
    {"name": "🎬 奈飞解锁", "type": "select", "proxies": proxy_names},
    {"name": "🤖 ChatGPT", "type": "select", "proxies": proxy_names},
    {"name": "🛑 广告拦截", "type": "select", "proxies": ["REJECT", "DIRECT"]},
    {"name": "⚡ 全局代理", "type": "select", "proxies": ["🚀 自动选择","📱 社交媒体","🎥 视频媒体","🎮 游戏加速","🎬 奈飞解锁","🤖 ChatGPT","🛑 广告拦截","DIRECT"]},
    {"name": "🛡️ 策略选择", "type": "select", "proxies": ["⚡ 全局代理","🚀 自动选择"]},
]
config["proxy-groups"] = groups

# ======================
# 输出文件（带更新时间）
# ======================
last_update = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
with open(OUTFILE, "w", encoding="utf-8") as f:
    f.write(f"# Last Update: {last_update}\n")
    yaml.dump(config, f, allow_unicode=True)

print(f"✅ 生成 {OUTFILE} (更新时间: {last_update})")
