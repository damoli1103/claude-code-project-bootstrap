#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Skip binary and non-text files
case "$FILE_PATH" in
  *.png|*.jpg|*.jpeg|*.gif|*.ico|*.woff|*.woff2|*.ttf|*.eot|*.pdf|*.zip|*.tar|*.gz) exit 0;;
esac

FOUND=0

# API keys and tokens
if grep -nE '(sk-[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|glpat-[a-zA-Z0-9\-]{20,})' "$FILE_PATH" 2>/dev/null; then
  echo "WARNING: Possible API key or token found in $FILE_PATH" >&2
  FOUND=1
fi

# Hardcoded secrets in assignments
if grep -nE "(API_KEY|SECRET_KEY|PASSWORD|PRIVATE_KEY|ACCESS_TOKEN|AUTH_TOKEN)\s*=\s*[\"'][^\"']{8,}" "$FILE_PATH" 2>/dev/null; then
  echo "WARNING: Possible hardcoded secret assignment in $FILE_PATH" >&2
  FOUND=1
fi

# Private keys
if grep -lE '-----BEGIN.*(PRIVATE KEY|RSA|DSA|EC)' "$FILE_PATH" 2>/dev/null; then
  echo "WARNING: Private key material found in $FILE_PATH" >&2
  FOUND=1
fi

# JWT tokens
if grep -nE 'eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}' "$FILE_PATH" 2>/dev/null; then
  echo "WARNING: Possible JWT token found in $FILE_PATH" >&2
  FOUND=1
fi

if [ "$FOUND" -eq 1 ]; then
  echo "Review the above warnings. Use environment variables or a secrets manager instead of hardcoding values." >&2
fi

# Always exit 0 — this is a non-blocking warning
exit 0
