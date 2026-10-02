<#
  install-harness-rules.ps1
  ----------------------------------------------------------------------------
  把 Harness 工程化规则文档下载到当前项目的 docs\ 目录（Windows PowerShell 版）

  用法（本地文件模式）：
    powershell -NoProfile -ExecutionPolicy Bypass -File .\install-harness-rules.ps1

  用法（远程一行，推荐：先落地再执行，绕开 iex 的编码不确定性）：
    $u='https://raw.githubusercontent.com/Tairraos/harness-go/master/scripts/install-harness-rules.ps1'
    $p="$env:TEMP\install-harness-rules.ps1"; iwr -UseBasicParsing $u -OutFile $p; & $p

  不带参数运行时会先问一句「新建项目还是改造存量项目」，再下载对应的那一份。
  落地目录固定为 docs\ —— 规则文档内部约定的路径就是它，不提供改目录的参数。

  远程一行模式下没法直接传命令行参数，需要跳过询问时改用环境变量：
    HARNESS_ONLY / HARNESS_MIRROR / HARNESS_REF
    HARNESS_OWNER / HARNESS_REPO / HARNESS_BASE_GITHUB / HARNESS_BASE_JSDELIVR

  Windows 上的两个坑，本脚本已处理：
    1. PowerShell 里 curl 是 Invoke-WebRequest 的别名，直接照搬 .sh 会出错 —— 本脚本全程用
       Invoke-WebRequest 显式调用，不依赖 curl。
    2. PowerShell 5.1 读 .ps1 时若文件没有 UTF-8 BOM，中文会变乱码 —— 本文件以
       UTF-8 with BOM 保存，不要用会丢 BOM 的编辑器另存。

  另外：所有含中文的输出都用「单引号字面量 + 变量拼接」拼出来，不把变量嵌进中文串里。
  原因是 PowerShell 允许 Unicode 字母做变量名，若变量后紧跟中文字符，会被当成变量名的一部分。
#>
[CmdletBinding()]
param(
    [string]$Only,
    [string]$Mirror,
    [string]$Ref
)

$ErrorActionPreference = 'Stop'
# 关掉进度条：Windows PowerShell 5.1 下进度条渲染会显著拖慢下载
$ProgressPreference = 'SilentlyContinue'

# ---------- 参数：命令行 > 环境变量 > 默认值 ----------
$Dir = 'docs'      # 固定，不提供改名
if (-not $Only)   { if ($env:HARNESS_ONLY)   { $Only   = $env:HARNESS_ONLY } }
if (-not $Mirror) { if ($env:HARNESS_MIRROR) { $Mirror = $env:HARNESS_MIRROR } else { $Mirror = 'auto' } }
if (-not $Ref)    { if ($env:HARNESS_REF)    { $Ref    = $env:HARNESS_REF }    else { $Ref    = 'master' } }

if ($env:HARNESS_OWNER) { $Owner = $env:HARNESS_OWNER } else { $Owner = 'Tairraos' }
if ($env:HARNESS_REPO)  { $Repo  = $env:HARNESS_REPO }  else { $Repo  = 'harness-go' }
$RemoteDir = 'rules'

# ---------- 询问要哪一份 ----------
function Select-Only {
    # 输入或输出任一被重定向就不问：问了也读不到答案，或者答案提示对方看不见。
    # 不做询问时静默下两份，绝不挂在等待输入上。
    $canAsk = $true
    try {
        if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { $canAsk = $false }
    } catch { }

    if (-not $canAsk) {
        Write-Host '（无终端可询问，两份都下）'
        return 'all'
    }

    Write-Host ''
    Write-Host '这个项目属于哪种情况？' -ForegroundColor Cyan
    Write-Host '  1) 新建项目 —— 从一个空仓库起步'
    Write-Host '  2) 改造存量项目 —— 已有代码库'

    $ans = ''
    try {
        $line = Read-Host -Prompt '输入 1 或 2（直接回车 = 两份都下）'
        if ($null -ne $line) { $ans = $line.Trim() }
    } catch {
        Write-Host '（无法读取输入，两份都下）'
        return 'all'
    }

    switch ($ans) {
        '1'        { return 'new' }
        '2'        { return 'existing' }
        'new'      { return 'new' }
        'existing' { return 'existing' }
        ''         { return 'all' }
        default    { Write-Host '  （没看懂，两份都下）'; return 'all' }
    }
}

if (-not $Only) {
    $Only = Select-Only
}

# ---------- 待下载清单 ----------
$fileNew      = 'new-project-harness-rules.md'
$fileExisting = 'turn-project-to-harness-rules.md'

if ($Only -eq 'all') {
    $list = @($fileNew, $fileExisting)
} elseif ($Only -eq 'new') {
    $list = @($fileNew)
} elseif ($Only -eq 'existing') {
    $list = @($fileExisting)
} else {
    throw ('--only 只能是 all / new / existing，收到：' + $Only)
}

# ---------- 下载源（按序降级） ----------
# 中国大陆实测：raw.githubusercontent.com 与 cdn/fastly.jsdelivr 常不通；
# 实时回源的 ghproxy 排在带 CDN 缓存的 jsDelivr 之前，避免刚推完拿到旧版。
$rawBase      = 'https://raw.githubusercontent.com/' + $Owner + '/' + $Repo + '/' + $Ref + '/' + $RemoteDir
$gpNetBase    = 'https://ghproxy.net/https://raw.githubusercontent.com/' + $Owner + '/' + $Repo + '/' + $Ref + '/' + $RemoteDir
$gpComBase    = 'https://gh-proxy.com/https://raw.githubusercontent.com/' + $Owner + '/' + $Repo + '/' + $Ref + '/' + $RemoteDir
$jsdGcoreBase = 'https://gcore.jsdelivr.net/gh/' + $Owner + '/' + $Repo + '@' + $Ref + '/' + $RemoteDir
$jsdCdnBase   = 'https://cdn.jsdelivr.net/gh/' + $Owner + '/' + $Repo + '@' + $Ref + '/' + $RemoteDir

# 便于 fork 与自测
if ($env:HARNESS_BASE_GITHUB)   { $rawBase      = $env:HARNESS_BASE_GITHUB }
if ($env:HARNESS_BASE_JSDELIVR) { $jsdGcoreBase = $env:HARNESS_BASE_JSDELIVR }

switch ($Mirror) {
    'github'   { $sources = @('github raw|'      + $rawBase) }
    'ghproxy'  { $sources = @('ghproxy.net|'     + $gpNetBase,
                              'gh-proxy.com|'    + $gpComBase) }
    'jsdelivr' { $sources = @('gcore.jsdelivr|'  + $jsdGcoreBase,
                              'cdn.jsdelivr|'    + $jsdCdnBase) }
    'auto'     { $sources = @('github raw|'      + $rawBase,
                              'ghproxy.net|'     + $gpNetBase,
                              'gh-proxy.com|'    + $gpComBase,
                              'gcore.jsdelivr|'  + $jsdGcoreBase,
                              'cdn.jsdelivr|'    + $jsdCdnBase) }
    default    { throw ('--mirror 只能是 auto / github / ghproxy / jsdelivr，收到：' + $Mirror) }
}

# 依次尝试各源，命中即返回源名；全部失败返回 $null
function Get-RuleFile {
    param([string]$Name, [string]$OutPath)
    foreach ($s in $sources) {
        $parts = $s.Split('|')
        try {
            Invoke-WebRequest -Uri ($parts[1] + '/' + $Name) -OutFile $OutPath -UseBasicParsing -TimeoutSec 180
            return $parts[0]
        } catch {
            # 这个源不通，换下一个
        }
    }
    return $null
}

# ---------- 执行 ----------
if (-not (Test-Path -LiteralPath $Dir)) {
    New-Item -ItemType Directory -Force -Path $Dir | Out-Null
}

Write-Host ''
Write-Host ('下载 Harness 规则文档 → ' + $Dir + '\') -ForegroundColor Cyan
Write-Host ''

$okCount = 0
foreach ($f in $list) {
    $out = Join-Path $Dir $f
    Write-Host ('  · ' + $f + ' ... ') -NoNewline

    $via = Get-RuleFile -Name $f -OutPath $out

    if (-not $via) {
        if (Test-Path -LiteralPath $out) {
            Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue
        }
        Write-Host '失败' -ForegroundColor Red
        Write-Host ''
        Write-Host '所有下载源都不可用。可手动试这几个地址：' -ForegroundColor Yellow
        foreach ($s in $sources) { Write-Host ('  ' + $s.Split('|')[1] + '/' + $f) }
        Write-Host ''
        Write-Host ('或直接克隆仓库后自行复制：https://github.com/' + $Owner + '/' + $Repo)
        throw ('无法下载 ' + $f)
    }

    # 落盘自检：防止把 404 / HTML 错误页当成文档存下来
    $len = (Get-Item -LiteralPath $out).Length
    if ($len -le 0) {
        Write-Host '失败（文件为空）' -ForegroundColor Red
        throw ('文件为空：' + $f)
    }

    $firstLine = Get-Content -LiteralPath $out -TotalCount 1 -Encoding UTF8
    if (-not ($firstLine -match '^#\s')) {
        Write-Host '失败（内容不像规则文档，可能下到了错误页）' -ForegroundColor Red
        throw ('内容校验未通过：' + $f)
    }

    Write-Host ('OK（' + $len + ' 字节，via ' + $via + '）') -ForegroundColor Green
    $okCount = $okCount + 1
}

Write-Host ''
Write-Host ('完成：' + $okCount + ' 份文档已放入 ' + (Resolve-Path -LiteralPath $Dir).Path) -ForegroundColor Green

# ---------- 下一步提示 ----------
Write-Host ''
Write-Host '接下来：'

if ($Only -ne 'existing') {
    Write-Host ''
    Write-Host '  【新建项目】新开一个 AI 会话，把这句话发给它：' -ForegroundColor Cyan
    Write-Host ('    阅读 ' + $Dir + '/' + $fileNew + '，严格按规则体系从 Day 0 搭建这个项目。')
    Write-Host '    第一步先处理我的需求（§3.2）：把需求复述给我确认，再提取技术栈；'
    Write-Host '    语言或框架不明确时必须通过交互向我确认，不要自己假设。'
    Write-Host '    技术栈定了再做 §3.3 框架确认；若确认为 Tauri，必须按 §3.4 逐条问我，问完再动手。'
}

if ($Only -ne 'new') {
    Write-Host ''
    Write-Host '  【改造存量项目】新开一个 AI 会话，把这句话发给它：' -ForegroundColor Cyan
    Write-Host ('    阅读 ' + $Dir + '/' + $fileExisting + '，严格按其第 5 节五阶段流程对本项目执行改造。')
    Write-Host '    先只做阶段 1：全量扫描并输出改造计划到 docs/exec-plans/active/，把问题清单写入'
    Write-Host '    docs/exec-plans/tech-debt-tracker.md。不要修改任何业务代码，等我确认计划。'
}

Write-Host ''
