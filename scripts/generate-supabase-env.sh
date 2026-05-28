#!/usr/bin/env sh
set -eu

ENV_FILE="${1:-.env}"
TEMPLATE_FILE="${TEMPLATE_FILE:-.env.example}"

if [ ! -f "$TEMPLATE_FILE" ]; then
  printf '%s\n' "Missing $TEMPLATE_FILE" >&2
  exit 1
fi

if [ -f "$ENV_FILE" ]; then
  printf '%s\n' "$ENV_FILE already exists. Move it away before regenerating secrets." >&2
  exit 1
fi

cp "$TEMPLATE_FILE" "$ENV_FILE"

random_base64() {
  openssl rand -base64 "$1" | tr -d '\n'
}

random_hex() {
  openssl rand -hex "$1"
}

random_alnum() {
  LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$1"
}

b64url() {
  openssl base64 -A | tr '+/' '-_' | tr -d '='
}

make_jwt() {
  role="$1"
  secret="$2"
  now="$(date +%s)"
  exp="$((now + 315360000))"
  header="$(printf '{"alg":"HS256","typ":"JWT"}' | b64url)"
  payload="$(printf '{"role":"%s","iss":"supabase-demo","iat":%s,"exp":%s}' "$role" "$now" "$exp" | b64url)"
  signature="$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -hmac "$secret" -binary | b64url)"
  printf '%s.%s.%s' "$header" "$payload" "$signature"
}

set_env() {
  key="$1"
  value="$2"
  tmp="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    BEGIN { found = 0 }
    $0 ~ "^" key "=" { print key "=" value; found = 1; next }
    { print }
    END { if (found == 0) print key "=" value }
  ' "$ENV_FILE" > "$tmp"
  mv "$tmp" "$ENV_FILE"
}

jwt_secret="$(random_base64 48)"

set_env POSTGRES_PASSWORD "$(random_hex 24)"
set_env JWT_SECRET "$jwt_secret"
set_env ANON_KEY "$(make_jwt anon "$jwt_secret")"
set_env SERVICE_ROLE_KEY "$(make_jwt service_role "$jwt_secret")"
set_env DASHBOARD_PASSWORD "$(random_alnum 28)"
set_env SECRET_KEY_BASE "$(random_base64 48)"
set_env VAULT_ENC_KEY "$(random_hex 16)"
set_env PG_META_CRYPTO_KEY "$(random_base64 32)"
set_env LOGFLARE_PUBLIC_ACCESS_TOKEN "$(random_base64 32)"
set_env LOGFLARE_PRIVATE_ACCESS_TOKEN "$(random_base64 32)"
set_env S3_PROTOCOL_ACCESS_KEY_ID "$(random_hex 16)"
set_env S3_PROTOCOL_ACCESS_KEY_SECRET "$(random_hex 32)"
set_env POOLER_TENANT_ID "$(random_hex 8)"

printf '%s\n' "Generated $ENV_FILE. Update public URLs and SMTP values before deploying."
