#!/bin/bash
# Health check for the plugin

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Running plugin health check..."
echo ""

ERRORS=0

# Check SuperThings build
if [ -f "$PLUGIN_ROOT/servers/super-things/dist/index.js" ]; then
  echo "✓ SuperThings built"
else
  echo "✗ SuperThings not built - run: cd $PLUGIN_ROOT/servers/super-things && npm run build"
  ((ERRORS++))
fi

# Check unifi venv
if [ -f "$PLUGIN_ROOT/servers/unifi/venv/bin/python" ]; then
  echo "✓ Unifi venv exists"
else
  echo "✗ Unifi venv missing - run: cd $PLUGIN_ROOT/servers/unifi && python3 -m venv venv"
  ((ERRORS++))
fi

# Check required env vars
echo ""
echo "Checking credentials..."
REQUIRED_VARS="THINGS_AUTH_TOKEN HUNTER_API_KEY TAVILY_API_KEY XERO_CLIENT_ID ZAPIER_MCP_TOKEN"
for var in $REQUIRED_VARS; do
  if [ -n "${!var}" ]; then
    echo "✓ $var is set"
  else
    echo "✗ $var is MISSING - store with: deep-env store $var 'value'"
    ((ERRORS++))
  fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "All checks passed!"
else
  echo "$ERRORS issue(s) found"
  exit 1
fi
