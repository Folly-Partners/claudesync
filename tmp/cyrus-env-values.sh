#!/bin/bash
# Extract all environment values for Cyrus VPS setup
# Usage: ./cyrus-env-values.sh

echo "=== Cyrus VPS Environment Values ==="
echo ""
echo "Copy these values when the browser LLM asks for them:"
echo ""

get_value() {
  local key=$1
  local value=$(~/.local/bin/deep-env get "$key" 2>/dev/null)
  if [ -z "$value" ]; then
    echo "$key=<NOT FOUND>"
  else
    echo "$key=$value"
  fi
}

echo "# MCP Plugin Authentication"
get_value "SUPABASE_ACCESS_TOKEN"
echo "SUPABASE_PROJECT_REF=isacmcgxnldcvlbnkurb"
echo ""

echo "# Application Runtime"
get_value "ANTHROPIC_API_KEY"
get_value "NEXT_PUBLIC_SUPABASE_URL"
get_value "NEXT_PUBLIC_SUPABASE_ANON_KEY"
get_value "SUPABASE_SERVICE_ROLE_KEY"
get_value "API_SECRET_KEY"
get_value "ADMIN_EMAILS"
get_value "NEXT_PUBLIC_APP_URL"
get_value "STRIPE_SECRET_KEY"
get_value "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY"
get_value "STRIPE_WEBHOOK_SECRET"
get_value "STRIPE_PRICE_BUNDLE"
get_value "STRIPE_PRICE_COMPARISON"
get_value "STRIPE_PRICE_FULL_REPORT"
get_value "GMAIL_USER"
get_value "GMAIL_APP_PASSWORD"
get_value "SENTRY_API_TOKEN"

echo ""
echo "=== Ready to paste into Cyrus ==="
