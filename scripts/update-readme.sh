#!/usr/bin/env bash
# shellcheck disable=SC2016 # backticks in the jq filters are Markdown, not shell
# Refresh the auto-generated block of README.md from public GitHub data.
# Needs: gh (authenticated through GH_TOKEN) and python3.
set -euo pipefail

readonly OWNER="AlonsoFloo"
readonly README="${1:-README.md}"

latest_release=$(gh api "repos/${OWNER}/skills/releases/latest" \
  --jq '"[`\(.tag_name)`](\(.html_url)), published \(.published_at[:10])"')

recent_prs=$(gh api -X GET search/issues \
  -f q="is:pr is:merged is:public user:${OWNER} -author:app/renovate" \
  -f sort=updated -f per_page=5 \
  --jq '.items[] | "- [\(.title)](\(.html_url)) in `\(.repository_url | split("/") | last)`"')

renovate_count=$(gh api -X GET search/issues \
  -f q="is:pr is:merged is:public user:${OWNER} author:app/renovate" \
  --jq '.total_count')

block=$(cat <<MD
- 🧠 Latest [\`skills\`](https://github.com/${OWNER}/skills) release: ${latest_release}
- 🤖 Renovate pull requests merged in my public repos: **${renovate_count}**, and counting

Recently merged:

${recent_prs}

<sub>Updated daily by a GitHub Action.</sub>
MD
)

BLOCK="${block}" python3 - "${README}" <<'PY'
import os, re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
new = re.sub(
    r"(<!-- LATEST:START -->\n).*?(<!-- LATEST:END -->)",
    lambda m: f"{m.group(1)}\n{os.environ['BLOCK']}\n\n{m.group(2)}",
    text,
    flags=re.S,
)
open(path, "w", encoding="utf-8").write(new)
PY
