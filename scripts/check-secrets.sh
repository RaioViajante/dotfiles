#!/bin/bash
set -euo pipefail

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
found=0

report_find() {
  local label="$1"
  shift
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    printf '%s: %s\n' "$label" "${file#"$root"/}"
    found=1
  done < <(find "$root" "$@" -print 2>/dev/null)
}

report_find 'forbidden private key' -type f \( \
  -name 'id_rsa' -o -name 'id_ed25519' -o -name 'id_ecdsa' -o \
  -name '*.pem' -o -name '*.p12' -o -name '*.pfx' \) \
  ! -path '*/.git/*'

report_find 'forbidden environment file' -type f \
  \( -name '.env' -o -name '.env.*' \) ! -name '.env.example' ! -path '*/.git/*'

report_find 'forbidden authentication file' -type f \( \
  -name 'auth.json' -o -name 'hosts.yml' -o -name 'credentials' -o \
  -name 'credentials.json' -o -name 'configstore.json' \) ! -path '*/.git/*'

while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  printf 'private-key content: %s\n' "${file#"$root"/}"
  found=1
done < <(rg -l --hidden --glob '!**/.git/**' --glob '!scripts/check-secrets.sh' \
  -- 'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY' "$root" 2>/dev/null || true)

while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  printf 'credential-like content: %s\n' "${file#"$root"/}"
  found=1
done < <(rg -l --hidden --glob '!**/.git/**' --glob '!scripts/check-secrets.sh' \
  -- '(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|(api[_-]?key|access[_-]?token|client[_-]?secret|password)[[:space:]]*[:=][[:space:]]*[^[:space:]$<{][^[:space:]]{7,})' \
  "$root" 2>/dev/null || true)

# The negative lookaheads skip non-email tokens that share the user@domain
# shape: the Git SSH remote and the public GNOME Shell extension UUIDs used by
# scripts/fedora/70-gnome.sh.
email_pattern='(?<![A-Za-z0-9._%+-])(?!git@github\.com\b)(?!clipboard-indicator@tudmotu\.com\b)(?!background-logo@fedorahosted\.org\b)[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  printf 'email-like content: %s\n' "${file#"$root"/}"
  found=1
done < <(rg -l --pcre2 --hidden --glob '!**/.git/**' --glob '!scripts/check-secrets.sh' \
  -- "$email_pattern" "$root" 2>/dev/null || true)

if (( found )); then
  echo "Secret scan failed. Values were intentionally not printed." >&2
  exit 1
fi

echo "Secret scan passed: no known private keys, auth files, environment files or credential patterns found."
