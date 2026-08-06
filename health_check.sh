#!/usr/bin/env bash
#
# Health Check & Setup Validator for Local Sandboxed Coding Agent
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for --proxy flag or existing proxy environment variables
CHECK_PROXY=false
if [ "$1" = "--proxy" ] || [ "$1" = "-p" ] || [ -n "$HTTP_PROXY" ] || [ -n "$SEATBELT_PROFILE" ]; then
    CHECK_PROXY=true
fi

echo "=================================================="
echo " Local Sandboxed Coding Agent — Health Check"
echo "=================================================="
echo ""

ERRORS=0
WARNINGS=0

# 1. Check Ollama service (Required for all setups)
echo -n "[1/4] Checking Ollama Service (127.0.0.1:11434)... "
if curl -s --max-time 3 http://127.0.0.1:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo "      Ollama service is not reachable on port 11434."
    echo "      Ensure Ollama is running on the Admin account and bound to 127.0.0.1."
    ERRORS=$((ERRORS + 1))
fi

# 2. Check Sandbox Environment / Execution
echo -n "[2/4] Checking Sandbox Execution Mode... "
if [ "$QWEN_SANDBOX" = "sandbox-exec" ]; then
    echo -e "${GREEN}OK${NC} (QWEN_SANDBOX=sandbox-exec)"
else
    echo -e "${YELLOW}NOTE${NC} (QWEN_SANDBOX not set; Qwen Code will use default sandbox)"
fi

# 3. Check Tinyproxy service (Optional setup from proxy.md)
echo -n "[3/4] Checking Tinyproxy (127.0.0.1:8877)... "
if [ "$CHECK_PROXY" = true ]; then
    if nc -z -w 3 127.0.0.1 8877 > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        echo "      Tinyproxy is not listening on port 8877."
        echo "      Ensure Tinyproxy service is started ('brew services start tinyproxy')."
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${BLUE}SKIPPED${NC} (Optional proxy setup — use '--proxy' to enable)"
fi

# 4. Check Seatbelt profile file (Optional setup from proxy.md)
echo -n "[4/4] Checking Seatbelt Profile file... "
if [ "$CHECK_PROXY" = true ]; then
    if [ -f ".qwen/sandbox-macos-permissive-proxied-ollama.sb" ]; then
        echo -e "${GREEN}OK${NC} (Found in .qwen/)"
    elif [ -f "$HOME/.qwen/sandbox-macos-permissive-proxied-ollama.sb" ]; then
        echo -e "${GREEN}OK${NC} (Found in ~/.qwen/)"
    else
        echo -e "${YELLOW}WARNING${NC}"
        echo "      Profile '.qwen/sandbox-macos-permissive-proxied-ollama.sb' not found."
        echo "      Copy or symlink the .sb profile to your project's .qwen folder."
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${BLUE}SKIPPED${NC} (Optional proxy setup — see proxy.md)"
fi

echo ""
echo "--------------------------------------------------"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed! Ready to run Qwen Code.${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}Checks completed with $WARNINGS warning(s).${NC}"
else
    echo -e "${RED}Health check completed with $ERRORS error(s) and $WARNINGS warning(s).${NC}"
fi
echo "=================================================="
