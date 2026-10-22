#!/usr/bin/env bash
# linkCheck.sh - verify documentation cross-references.
#  1. Every relative markdown link target `](target)` in tracked or new
#     .md files exists (anchors stripped; http/mailto skipped).
#  2. Every `#anchor` in those links matches a heading (anchorCheck.py).
#  3. Every `*.md` filename mentioned in .md/.m files (fun/ext
#     excluded) names an existing .md file.
# Usage: bash testing/linkCheck.sh   Exit status: 0 if clean, 1 otherwise.
# NOTE: one grep over all files; per-file pipelines take minutes.
cd "$(git rev-parse --show-toplevel)" || exit 2
mapfile -t MD < <( { git ls-files '*.md'; git ls-files --others \
    --exclude-standard '*.md'; } | sort -u)
bad=0; nlinks=0; nnames=0

while IFS= read -r hit; do
    f="${hit%%:*}"; tgt="${hit#*:}"
    tgt="${tgt#](}"; tgt="${tgt%)}"; tgt="${tgt%%#*}"
    [[ -z "$tgt" || "$tgt" =~ ^(https?:|mailto:) ]] && continue
    nlinks=$(( nlinks + 1 ))
    if [[ ! -e "$(dirname "$f")/$tgt" ]]; then
        echo "BROKEN LINK  $f -> $tgt"; bad=$(( bad + 1 ))
    fi
done < <(grep -oHE '\]\([^) ]+\)' "${MD[@]}" 2>/dev/null | tr -d '\r')

declare -A HAVE
for f in "${MD[@]}"; do HAVE["${f##*/}"]=1; done
mapfile -t SRC < <( { git ls-files '*.md' '*.m'; git ls-files --others \
    --exclude-standard '*.md' '*.m'; } | grep -v '^fun/ext/' | sort -u)
while IFS= read -r hit; do
    f="${hit%%:*}"; name="${hit#*:}"
    [[ "${name##*/}" == ".md" ]] && continue
    nnames=$(( nnames + 1 ))
    if [[ -z "${HAVE[${name##*/}]}" ]]; then
        echo "MISSING MD   $f mentions $name"; bad=$(( bad + 1 ))
    fi
done < <(grep -oHE '[A-Za-z0-9_./-]+\.md\b' "${SRC[@]}" 2>/dev/null \
    | tr -d '\r')
py="$(command -v python || command -v python3)"
"$py" "$(dirname "${BASH_SOURCE[0]}")/anchorCheck.py" "${MD[@]}"     || bad=$(( bad + 1 ))
echo "links checked: $nlinks; .md mentions checked: $nnames; problems: $bad"
(( bad == 0 ))
