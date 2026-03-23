#!/usr/bin/env bash
# Generic MCP server launcher that loads secrets from mcp.env
# Usage: mcp-env.sh <command> [args...]
# Example: mcp-env.sh uvx workspace-mcp --single-user
#
# Reads environment variables from mcp.env (same directory as this script)
# before launching the specified MCP server command.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/mcp.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

exec "$@"
