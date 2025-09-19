import yaml, requests, datetime, os, glob
SUB_URLS = [
    "https://node.freeclashnode.com/uploads/2025/09/1-{}.yaml".format(datetime.datetime.now().strftime("%Y%m%d")),
    "https://raw.githubusercontent.com/free-clash-v2ray/free-clash-v2ray.github.io/main/uploads/{}/1-{}.yaml".format(
        datetime.datetime.now().strftime("%Y/%m"), datetime.datetime.now().strftime("%Y%m%d")
    )
]
OUTFILE = "clash-meta-config.yaml"
BASE_FILE = "config/base.yaml"
GROUPS_FILE = "config/groups.yaml"
RULES_FILE = "config/rules.yaml"
HISTORY_DIR = "history"
MAX_HISTORY = 30
os.makedirs(HISTORY_DIR, exist_ok=True)
# 节点订阅
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
with open(BASE_FILE, "r", encoding="utf-8") as f:
    config = yaml.safe_load(f)
config["proxies"] = nodes.get("proxies", [])
# 加载分组结构, 并补齐节点
with open(GROUPS_FILE, "r", encoding="utf-8") as f:
    groups = yaml.safe_load(f)
if "proxy-groups" in groups:
    for g in groups["proxy-groups"]:
        if g.get("type") in ["url-test", "fallback", "select"] and "proxies" in g:
            g["proxies"] = proxy_names
config["proxy-groups"] = groups["proxy-groups"]
# 合入规则分段
with open(RULES_FILE, "r", encoding="utf-8") as f:
    ruleconf = yaml.safe_load(f)
config["rules"] = ruleconf.get("rules", [])
# 输出主配置及历史归档
last_update = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
timestamp = datetime.datetime.utcnow().strftime("%Y%m%d_%H%M%S")
with open(OUTFILE, "w", encoding="utf-8") as f:
    f.write(f"# Last Update: {last_update}\n")
    yaml.dump(config, f, allow_unicode=True, default_flow_style=False)
history_file = os.path.join(HISTORY_DIR, f"config_{timestamp}.yaml")
with open(history_file, "w", encoding="utf-8") as f:
    f.write(f"# Last Update: {last_update}\n")
    yaml.dump(config, f, allow_unicode=True, default_flow_style=False)
print(f"✅ 已生成 {OUTFILE}")
# 自动清理老旧历史
history_list = sorted(glob.glob(os.path.join(HISTORY_DIR, "config_*.yaml")))
if len(history_list) > MAX_HISTORY:
    for old_file in history_list[:-MAX_HISTORY]:
        try:
            os.remove(old_file)
            print(f"🧹 已清理旧归档: {old_file}")
        except Exception as e:
            print(f"⚠️ 清理失败: {old_file}, {e}")
