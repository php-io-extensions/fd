#!/bin/bash

# Portable installer for the HardwarePHP extension.
# - Detects php extension dir dynamically
# - Enables for available SAPIs (CLI/FPM/Apache) when present
# - Finds zephir automatically or respects $ZEPHIR_BIN
# - Provides clear preflight checks and verification

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSION_NAME="fd"
BUILD_SO="${SCRIPT_DIR}/ext/modules/${EXTENSION_NAME}.so"
LOG_FILE="${SCRIPT_DIR}/build.log"

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

die() {
    echo ""
    echo "❌ $*"
    exit 1
}

require_cmd() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

header() {
    echo "=========================================="
    echo "FD (FileDescriptor) Extension Installer (portable)"
    echo "=========================================="
    echo ""
}

step() {
    echo "$*"
}

ok() {
    echo "   ✓ $*"
}

header

# Preflight
step "🔎 Preflight checks..."
require_cmd php
require_cmd php-config

# Resolve Zephir
if [ -n "${ZEPHIR_BIN:-}" ]; then
    ZEPHIR="$ZEPHIR_BIN"
elif command -v zephir >/dev/null 2>&1; then
    ZEPHIR="$(command -v zephir)"
elif [ -x "$HOME/.config/composer/vendor/bin/zephir" ]; then
    ZEPHIR="$HOME/.config/composer/vendor/bin/zephir"
else
    die "Zephir not found. Install via composer (composer global require phalcon/zephir) or set ZEPHIR_BIN."
fi
ok "Found zephir: $ZEPHIR"

PHP_VER_MM="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
PHP_VER_NN="$(php -r 'echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;')"

# Resolve the real PHP binary (follows shims like Herd, asdf, etc.) then find
# the co-located php-config, which gives the correct extension dir for that build.
PHP_BIN_REAL="$(php -r 'echo PHP_BINARY;' 2>/dev/null)"
PHP_BIN_DIR="$(dirname "$PHP_BIN_REAL")"
RESOLVED_PHP_CONFIG="${PHP_BIN_DIR}/php-config"

if [ -x "$RESOLVED_PHP_CONFIG" ]; then
    PHP_EXT_DIR="$("$RESOLVED_PHP_CONFIG" --extension-dir)"
elif command -v php-config >/dev/null 2>&1; then
    PHP_EXT_DIR="$(php-config --extension-dir)"
else
    die "Could not locate php-config. Install it or set PHP_EXT_DIR manually."
fi
[ -n "$PHP_EXT_DIR" ] || die "Could not determine PHP extension dir."

# On setups like Laravel Herd the extensions live alongside ini files in the
# CLI scan dir, not in the path php-config reports. Detect this by checking
# for .so files already present in the scan dir and prefer it when found.
CLI_SCAN_DIR="$(php --ini 2>/dev/null | awk -F': ' '/Scan for additional \.ini files in:/{print $2}' || true)"
if [ -n "$CLI_SCAN_DIR" ] && [ -d "$CLI_SCAN_DIR" ] && \
   ls "$CLI_SCAN_DIR"/*.so >/dev/null 2>&1; then
    PHP_EXT_DIR="$CLI_SCAN_DIR"
fi

ok "PHP version: ${PHP_VER_MM}"
ok "PHP binary: ${PHP_BIN_REAL}"
ok "Extension dir: ${PHP_EXT_DIR}"

# Set safe CFLAGS for GCC 14 compatibility (override any invalid flags from environment)
# Suppress Zephir kernel code warnings that are harmless but break with GCC 14
export CFLAGS="-Wno-error -Wno-error=incompatible-pointer-types -Wno-pointer-compare"
export CPPFLAGS="${CPPFLAGS:-} -Wno-error -Wno-error=incompatible-pointer-types"
echo ""

# Clean previous build
step "🧹 Cleaning previous build..."
cd "${SCRIPT_DIR}"
if ! "$ZEPHIR" fullclean >"$LOG_FILE" 2>&1; then
    tail -50 "$LOG_FILE" || true
    die "Clean failed. See ${LOG_FILE}."
fi
ok "Clean complete"
echo ""

# Build
step "🔨 Building extension..."
if ! "$ZEPHIR" build >>"$LOG_FILE" 2>&1; then
    tail -80 "$LOG_FILE" || true
    die "Build failed. See ${LOG_FILE}."
fi
if [ ! -f "$BUILD_SO" ]; then
    tail -80 "$LOG_FILE" || true
    die "Build output not found at ${BUILD_SO}."
fi
ok "Build complete"
echo ""

# Install .so
step "📦 Installing binary..."
$SUDO mkdir -p "$PHP_EXT_DIR"
$SUDO cp -f "$BUILD_SO" "${PHP_EXT_DIR}/${EXTENSION_NAME}.so"
$SUDO chmod 755 "${PHP_EXT_DIR}/${EXTENSION_NAME}.so"
ok "Copied to: ${PHP_EXT_DIR}/${EXTENSION_NAME}.so"
echo ""

# Enable extension across detected SAPIs
step "⚙️  Enabling extension..."
declare -a CONF_DIR_CANDIDATES=()

# CLI scan dir — already resolved above for extension dir detection
if [ -n "$CLI_SCAN_DIR" ] && [ "$CLI_SCAN_DIR" != "(none)" ] && [ -d "$CLI_SCAN_DIR" ]; then
    CONF_DIR_CANDIDATES+=("$CLI_SCAN_DIR")
fi

# Debian/Ubuntu common paths
for d in "/etc/php/${PHP_VER_MM}/cli/conf.d" "/etc/php/${PHP_VER_MM}/fpm/conf.d" "/etc/php/${PHP_VER_MM}/apache2/conf.d"; do
    [ -d "$d" ] && CONF_DIR_CANDIDATES+=("$d")
done

# Alpine common path (e.g., /etc/php83/conf.d)
ALPINE_CONF="/etc/php${PHP_VER_NN}/conf.d"
[ -d "$ALPINE_CONF" ] && CONF_DIR_CANDIDATES+=("$ALPINE_CONF")

# FPM generic fallbacks
for d in "/etc/php-fpm.d" "/etc/php-fpm/conf.d"; do
    [ -d "$d" ] && CONF_DIR_CANDIDATES+=("$d")
done

# Deduplicate
CONF_DIRS=()
while IFS= read -r _line; do
    CONF_DIRS+=("$_line")
done < <(printf "%s\n" "${CONF_DIR_CANDIDATES[@]}" | awk '!seen[$0]++')

if [ "${#CONF_DIRS[@]}" -eq 0 ]; then
    echo "   ⚠️  No conf.d directories found; enabling only for current CLI context via php.d scan dir."
fi

INI_NAME="30-${EXTENSION_NAME}.ini"
INI_CONTENT="extension=${PHP_EXT_DIR}/${EXTENSION_NAME}.so"

for confd in "${CONF_DIRS[@]:-}"; do
    INI_PATH="${confd}/${INI_NAME}"
    echo "$INI_CONTENT" | $SUDO tee "$INI_PATH" >/dev/null
    ok "Written: $INI_PATH"
done
echo ""

# Verify CLI load
step "🔍 Verifying installation (CLI)..."
if php -m 2>/dev/null | grep -q "^fd$"; then
    ok "Extension loaded successfully in CLI"
else
    echo ""
    php -m 2>/dev/null | tail -n +1 >/dev/null || true
    die "Extension not detected in CLI. Check ${INI_NAME} placement and php --ini."
fi
echo ""

# Show module info
step "=========================================="
step "Extension Information (CLI)"
step "=========================================="
php --ri fd || true
echo ""

# Reload FPM if present
if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-units --type=service 2>/dev/null | grep -q "php${PHP_VER_MM}-fpm\.service"; then
        step "🔁 Reloading php${PHP_VER_MM}-fpm..."
        $SUDO systemctl reload "php${PHP_VER_MM}-fpm" || true
        ok "php${PHP_VER_MM}-fpm reloaded"
    elif systemctl list-units --type=service 2>/dev/null | grep -q "php-fpm\.service"; then
        step "🔁 Reloading php-fpm..."
        $SUDO systemctl reload "php-fpm" || true
        ok "php-fpm reloaded"
    fi
fi

echo "✅ Installation complete!"
echo ""
echo "File locations:"
echo "  • Binary: ${PHP_EXT_DIR}/${EXTENSION_NAME}.so"
if [ "${#CONF_DIRS[@]}" -gt 0 ]; then
    for d in "${CONF_DIRS[@]}"; do
        echo "  • Config: ${d}/${INI_NAME}"
    done
else
    echo "  • Config: (CLI scan dir via php --ini)"
fi
echo ""


