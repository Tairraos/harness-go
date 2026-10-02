#!/bin/sh
# install-harness-rules.sh — 把 Harness 工程化规则文档下载到当前项目的 doc/ 目录
#
# 用法：
#   sh scripts/install-harness-rules.sh                      # 两份都下载到 ./doc
#   sh scripts/install-harness-rules.sh --only new           # 只下载「新建项目」那份
#   sh scripts/install-harness-rules.sh --only existing      # 只下载「改造存量项目」那份
#   sh scripts/install-harness-rules.sh --dir docs           # 换个目录名
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
MIRROR="auto"   # auto | github | jsdelivr

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
  --dir <路径>     下载到哪个目录，默认 doc
  --only <选择>    下载哪几份：all（默认）/ new / existing
                     new      = 新建项目规则
                     existing = 存量项目改造规则
  --mirror <源>    下载源：auto（默认，GitHub 失败自动退 jsDelivr）/ github / jsdelivr
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

# ---------- 依赖检查 ----------
if ! command -v curl >/dev/null 2>&1; then
  echo "缺少 curl，无法下载。请先安装 curl 后重试。" >&2
  exit 1
fi

# ---------- 待下载清单 ----------
# new      → 新建项目（空仓库起步）
# existing → 改造存量项目（已有代码库）
FILES_NEW="new-project-harness-rules.md"
FILES_EXISTING="turn-project-to-harness-rules.md"

LIST=""
case "$ONLY" in
  all)      LIST="$FILES_NEW $FILES_EXISTING" ;;
  new)      LIST="$FILES_NEW" ;;
  existing) LIST="$FILES_EXISTING" ;;
esac

# ---------- 下载源 ----------
# 默认指向 GitHub；HARNESS_BASE_* 可覆盖（fork 或本地自测时用）
GITHUB_BASE="${HARNESS_BASE_GITHUB:-https://raw.githubusercontent.com/$OWNER/$REPO/$REF/$REMOTE_DIR}"
JSDELIVR_BASE="${HARNESS_BASE_JSDELIVR:-https://cdn.jsdelivr.net/gh/$OWNER/$REPO@$REF/$REMOTE_DIR}"

# fetch <文件名> <输出路径>
# auto 模式下先试 GitHub，失败再退 jsDelivr 镜像
fetch() {
  _name="$1"
  _out="$2"

  case "$MIRROR" in
    github)
      curl -fsSL --retry 2 --connect-timeout 15 "$GITHUB_BASE/$_name" -o "$_out"
      ;;
    jsdelivr)
      curl -fsSL --retry 2 --connect-timeout 15 "$JSDELIVR_BASE/$_name" -o "$_out"
      ;;
    auto)
      if curl -fsSL --retry 1 --connect-timeout 10 "$GITHUB_BASE/$_name" -o "$_out" 2>/dev/null; then
        return 0
      fi
      echo "    GitHub raw 不通，改用 jsDelivr 镜像重试…" >&2
      curl -fsSL --retry 2 --connect-timeout 15 "$JSDELIVR_BASE/$_name" -o "$_out"
      ;;
    *)
      echo "--mirror 只能是 auto / github / jsdelivr，收到：$MIRROR" >&2
      exit 2
      ;;
  esac
}

# ---------- 执行 ----------
mkdir -p "$TARGET_DIR"

echo "下载 Harness 规则文档 → $TARGET_DIR/"
echo ""

OK_COUNT=0
for f in $LIST; do
  out="$TARGET_DIR/$f"
  printf '  · %s ... ' "$f"
  fetch "$f" "$out"

  # 落盘自检：非空 + 是一份 Markdown 标题开头的规则文档
  if [ ! -s "$out" ]; then
    echo "失败（文件为空）" >&2
    exit 1
  fi
  if ! head -n 1 "$out" | grep -q '^# '; then
    echo "失败（内容不像规则文档，可能下到了错误页）" >&2
    exit 1
  fi

  size=$(wc -c < "$out" | tr -d ' ')
  echo "OK（${size} 字节）"
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
    阅读 $TARGET_DIR/${FILES_NEW}，严格按规则体系从 Day 0 搭建这个项目。
    先处理我的需求（§3.2）：复述需求给我确认，再提取技术栈；
    语言或框架不明确时必须问我，不要自己假设。
    技术栈定了再做 §3.3 框架确认；若为 Tauri，必须按 §3.4 逐条问我，问完再动手。
EOF
fi
if [ "$ONLY" != "new" ]; then
  cat <<EOF
  【改造存量项目】新开一个 AI 会话，把这句话发给它：
    阅读 $TARGET_DIR/${FILES_EXISTING}，严格按其第 5 节五阶段流程改造本项目。
    先只做阶段 1：全量扫描并输出改造计划，不要修改任何业务代码，等我确认计划。
EOF
fi
