#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

MODE="${1:---editor}"
echo "============================================================================"
echo "  NovaForge AI Game Engine — Launcher (Linux / macOS)"
echo "  Usage: ./run.sh [--editor | --play | --studio]"
echo "============================================================================"

python3 launcher/novaforge_launcher.py "$MODE"
