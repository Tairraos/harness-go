#!/bin/sh
# install-harness-rules.sh — 把 Harness 工程化规则文档下载到当前项目的 doc/ 目录
#
# 用法：
#   sh scripts/install-harness-rules.sh                      # 两份都下载到 ./doc
#   sh scripts/install-harness-rules.sh --only new           # 只下载「新建项目」那份
#   sh scripts/install-harness-rules.sh --only existing      # 只下载「改造存量项目」那份
#   sh scripts/install-harness-rules.sh --dir docs           # 换个落地目录名
#
# 远程执行（推荐，一条命令）：
#   curl -fsSL https://raw.githubusercontent.com/Tairraos/harness-go/master/scripts/install-harness-rules.sh | sh
#
# 依赖：curl（macOS / Linux 自带）

set -eu

# ---------- 可覆盖参数 ----------
OWNER="${HARNESS_OWNER:-Tairraos}"
REPO="${HARNESS_REPO:-harness-go}"
REF="${HARNESS_REF:-master}"
REMOTE_DIR="rules"

TARGET_DIR="doc"
ONLY="all"
MIRROR="auto"   # auto | github | ghproxy | jsdelivr

# ---------- 参数解析 ----------
while [ $# -gt 0 ]; do
  case "$1" in
    --dir)    TARGET_DIR="$2"; shift 2 ;;
    --only)   ONLY="$2";       shift 2 ;;
    --mirror) MIRROR="$2";     shift 2 ;;
    --ref)    REF="$2";        shift 2 ;;
    -h|--help)
      cat <<'USAGE'
用法：sh install-harness-rules.sh [选项]

  把 Harness 工程化规则文档下载到当前项目的 doc/ 目录。

选项：
  --dir <路径>     落地目录，默认 doc
  --only <选择>    下载哪几份：all（默认）/ new / existing
                     new      = 新建项目规则
                     existing = 存量项目改造规则
  --mirror <源>    下载源：auto（默认，按序自动降级）/ github / ghproxy / jsdelivr
                     auto 依次尝试：GitHub raw → ghproxy.net → gh-proxy.com
                                   → gcore.jsdelivr → cdn.jsdelivr
  --ref <分支>     文档所在的 Git ref，默认 master
  -h, --help       显示这段帮助

示例：
  sh install-harness-rules.sh
  sh install-harness-rules.sh --only new --dir docs
USAGE
      exit 0 ;;
    *) echo "未知参数：$1（用 --help 看用法）" >&2; exit 2 ;;
  esac
done

case "$ONLY" in
  all|new|existing) ;;
  *) echo "--only 只能是 all / new / existing，收到：$ONLY" >&2; exit 2 ;;
esac
case "$MIRROR" in
  auto|github|ghproxy|jsdelivr) ;;
  *) echo "--mirror 只能是 auto / github / ghproxy / jsdelivr，收到：$MIRROR" >&2; exit 2 ;;
esac

# ---------- 依赖检查 ----------
if ! command -v curl >/dev/null 2>&1; then
  echo "缺少 curl，无法下载。请先安装 curl 后重试。" >&2
  exit 1
fi

# ---------- 待下载清单 ----------
FILE_NEW="new-project-harness-rules.md"        # 新建项目（空仓库起步）
FILE_EXISTING="turn-project-to-harness-rules.md"  # 改造存量项目（已有代码库）

case "$ONLY" in
  all)      LIST="$FILE_NEW $FILE_EXISTING" ;;
  new)      LIST="$FILE_NEW" ;;
  existing) LIST="$FILE_EXISTING" ;;
esac

# ---------- 下载源（按序降级） ----------
# 实测：中国大陆直连 raw.githubusercontent.com 常被拦、cdn.jsdelivr.net 也可能不通，
# 故 auto 模式挂多源依次重试。ghproxy 类为实时回源，比 jsDelivr 有缓存更不易拿到旧版。
GH_RAW="https://raw.githubusercontent.com/$OWNER/$REPO/$REF/$REMOTE_DIR"
GH_PROXY_NET="https://ghproxy.net/https://raw.githubusercontent.com/$OWNER/$REPO/$REF/$REMOTE_DIR"
GH_PROXY_COM="https://gh-proxy.com/https://raw.githubusercontent.com/$OWNER/$REPO/$REF/$REMOTE_DIR"
JSD_GCORE="https://gcore.jsdelivr.net/gh/$OWNER/$REPO@$REF/$REMOTE_DIR"
JSD_CDN="https://cdn.jsdelivr.net/gh/$OWNER/$REPO@$REF/$REMOTE_DIR"

# 允许环境变量整体覆盖（fork 或自测时用）
GH_RAW="${HARNESS_BASE_GITHUB:-$GH_RAW}"
JSD_GCORE="${HARNESS_BASE_JSDELIVR:-$JSD_GCORE}"

case "$MIRROR" in
  github)   SOURCES="github raw|$GH_RAW" ;;
  ghproxy)  SOURCES="ghproxy.net|$GH_PROXY_NET gh-proxy.com|$GH_PROXY_COM" ;;
  jsdelivr) SOURCES="gcore.jsdelivr|$JSD_GCORE cdn.jsdelivr|$JSD_CDN" ;;
  auto)     SOURCES="github raw|$GH_RAW ghproxy.net|$GH_PROXY_NET gh-proxy.com|$GH_PROXY_COM gcore.jsdelivr|$JSD_GCORE cdn.jsdelivr|$JSD_CDN" ;;
esac

# fetch <文件名> <输出路径>
# 依次尝试各源，命中即返回；全部失败返回 1
fetch() {
  _name="$1"
  _out="$2"
  _label=""

  for _s in $SOURCES; do
    _host="${_s%%|*}"
    _base="${_s#*|}"
    if curl -fsSL --retry 1 --connect-timeout 10 --max-time 180 "$_base/$_name" -o "$_out" 2>/dev/null; then
      _label="$_host"
      break
    fi
  done

  if [ -z "$_label" ]; then
    return 1
  fi
  FETCH_VIA="$_label"
  return 0
}

# ---------- 执行 ----------
mkdir -p "$TARGET_DIR"

echo "下载 Harness 规则文档 → $TARGET_DIR/"
echo ""

OK_COUNT=0
for f in $LIST; do
  out="$TARGET_DIR/$f"
  printf '  · %s ... ' "$f"

  if ! fetch "$f" "$out"; then
    echo "失败"
    echo "" >&2
    echo "所有下载源都不可用。可以手动试这几个地址：" >&2
    for _s in $SOURCES; do
      echo "  ${_s#*|}/$f" >&2
    done
    echo "" >&2
    echo "或直接 git clone https://github.com/$OWNER/$REPO.git 后自行复制。" >&2
    exit 1
  fi

  # 落盘自检：非空 + 是一份 Markdown 标题开头的规则文档，防止把 404 页面存成文档
  if [ ! -s "$out" ]; then
    echo "失败（文件为空）" >&2
    exit 1
  fi
  if ! head -n 1 "$out" | grep -q '^# '; then
    echo "失败（内容不像规则文档，可能下到了错误页）" >&2
    exit 1
  fi

  _size=$(wc -c < "$out" | tr -d ' ')
  echo "OK（${_size} 字节，via ${FETCH_VIA}）"
  OK_COUNT=$((OK_COUNT + 1))
done

echo ""
echo "完成：$OK_COUNT 份文档已放入 $TARGET_DIR/"

# ---------- 下一步提示 ----------
echo ""
echo "接下来："
if [ "$ONLY" != "existing" ]; then
  cat <<EOF
  【新建项目】新开一个 AI 会话，把这句话发给它：
    阅读 $TARGET_DIR/${FILE_NEW}，严格按规则体系从 Day 0 搭建这个项目。
    第一步先处理我的需求（§3.2）：把需求复述给我确认，再提取技术栈；
    语言或框架不明确时必须通过交互向我确认，不要自己假设。
    技术栈定了再做 §3.3 框架确认；若确认为 Tauri，必须按 §3.4 逐条问我，问完再动手。
EOF
fi
if [ "$ONLY" != "new" ]; then
  cat <<EOF
  【改造存量项目】新开一个 AI 会话，把这句话发给它：
    阅读 $TARGET_DIR/${FILE_EXISTING}，严格按其第 5 节五阶段流程对本项目执行改造。
    先只做阶段 1：全量扫描并输出改造计划到 docs/exec-plans/active/，把问题清单写入
    docs/exec-plans/tech-debt-tracker.md。不要修改任何业务代码，等我确认计划。
EOF
fi
