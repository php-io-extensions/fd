#!/bin/bash

# Installer for the FD (FileDescriptor) extension on Debian Trixie
# (and compatible: Ubuntu 24.04+, Raspberry Pi OS Bookworm/Trixie).
#
# - Resolves PHP binary and extension dir automatically
# - Generates C sources via Zephir, patches them for GCC 14 / PHP 8.4
# - Compiles and installs

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

die()  { echo ""; echo "❌ $*"; exit 1; }
step() { echo "$*"; }
ok()   { echo "   ✓ $*"; }

show_failure_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "---- Last 80 lines of ${LOG_FILE} ----"
        tail -80 "$LOG_FILE" || true
    fi
}

echo "=========================================="
echo " FD (FileDescriptor) Extension Installer (Debian Trixie)"
echo "=========================================="
echo ""

# ── Preflight ────────────────────────────────────────────────────────────────
step "🔎 Preflight checks..."
command -v php       >/dev/null 2>&1 || die "php not found in PATH"
command -v php-config >/dev/null 2>&1 || die "php-config not found — install php8.x-dev"
command -v cc        >/dev/null 2>&1 || die "cc not found — install build-essential"

if [ -n "${ZEPHIR_BIN:-}" ]; then
    ZEPHIR="$ZEPHIR_BIN"
elif command -v zephir >/dev/null 2>&1; then
    ZEPHIR="$(command -v zephir)"
elif [ -x "$HOME/.config/composer/vendor/bin/zephir" ]; then
    ZEPHIR="$HOME/.config/composer/vendor/bin/zephir"
elif [ -x "$HOME/.composer/vendor/bin/zephir" ]; then
    ZEPHIR="$HOME/.composer/vendor/bin/zephir"
else
    die "Zephir not found. Install via: composer global require phalcon/zephir  (or set ZEPHIR_BIN)"
fi
ok "Found zephir: $ZEPHIR"

PHP_VER_MM="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
PHP_VER_NN="$(php -r 'echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;')"
PHP_BIN_REAL="$(php -r 'echo PHP_BINARY;' 2>/dev/null)"
PHP_BIN_DIR="$(dirname "$PHP_BIN_REAL")"
RESOLVED_PHP_CONFIG="${PHP_BIN_DIR}/php-config"
if ! [ -x "$RESOLVED_PHP_CONFIG" ]; then
    RESOLVED_PHP_CONFIG="$(command -v php-config)"
fi

PHP_EXT_DIR="$("$RESOLVED_PHP_CONFIG" --extension-dir 2>/dev/null)" \
    || die "Could not determine PHP extension dir from php-config."
[ -n "$PHP_EXT_DIR" ] || die "Could not determine PHP extension dir."

CLI_SCAN_DIR="$(php --ini 2>/dev/null | awk -F': ' '/Scan for additional \.ini files in:/{print $2}' || true)"

ok "PHP version:   ${PHP_VER_MM}"
ok "PHP binary:    ${PHP_BIN_REAL}"
ok "Extension dir: ${PHP_EXT_DIR}"

# GCC 14 on Trixie promotes -Wincompatible-pointer-types to a hard error.
# We patch the root cause in the kernel files (see below), but keep these
# flags as a safety net for any other Zephir kernel warnings.
export CFLAGS="${CFLAGS:-} -Wno-error -Wno-error=incompatible-pointer-types -Wno-error=int-conversion -Wno-pointer-compare"
export CPPFLAGS="${CPPFLAGS:-} -Wno-error -Wno-error=incompatible-pointer-types"
echo ""

# ── Clean ────────────────────────────────────────────────────────────────────
step "🧹 Cleaning previous build..."
cd "${SCRIPT_DIR}"
if ! "$ZEPHIR" fullclean >"$LOG_FILE" 2>&1; then
    show_failure_logs
    die "Clean failed. See ${LOG_FILE}."
fi
ok "Clean complete"
echo ""

# ── Generate C sources ────────────────────────────────────────────────────────
step "🔨 Generating C sources..."
"$ZEPHIR" generate >>"$LOG_FILE" 2>&1 || true

# ── Patch generated kernel files for PHP 8.4 / GCC 14 ────────────────────────
# ext/kernel/require.c and ext/kernel/file.c pass zend_string* to zval_ptr_dtor(),
# which expects zval*.  GCC 14 on Trixie treats this as a hard compile error.
# The correct destructor for zend_string* is zend_string_release().
step "   Patching ext/kernel for PHP 8.4 / GCC 14..."
REQUIRE_C="${SCRIPT_DIR}/ext/kernel/require.c"
FILE_C="${SCRIPT_DIR}/ext/kernel/file.c"
if [ -f "$REQUIRE_C" ]; then
    sed -i \
        's/zval_ptr_dtor(zend_string_path)/zend_string_release(zend_string_path)/g' \
        "$REQUIRE_C"
    ok "Patched ext/kernel/require.c"
fi
if [ -f "$FILE_C" ]; then
    sed -i \
        's/zval_ptr_dtor(file)/zend_string_release(file)/g' \
        "$FILE_C"
    ok "Patched ext/kernel/file.c"
fi

# ── Compile ───────────────────────────────────────────────────────────────────
step "   Compiling..."
cd "${SCRIPT_DIR}/ext"
# Remove stale .dep files that may have been committed from another machine.
# They contain absolute paths baked in at compile time; make regenerates them.
find . -name "*.dep" -delete 2>/dev/null || true
phpize >>"$LOG_FILE" 2>&1 || true
./configure "--with-php-config=${RESOLVED_PHP_CONFIG}" >>"$LOG_FILE" 2>&1 || true
make -j"$(nproc 2>/dev/null || echo 4)" >>"$LOG_FILE" 2>&1 || true
cd "${SCRIPT_DIR}"

if [ ! -f "$BUILD_SO" ]; then
    show_failure_logs
    die "Build output not found at ${BUILD_SO}."
fi
ok "Build complete"
echo ""

# ── Install .so ───────────────────────────────────────────────────────────────
step "📦 Installing binary..."
$SUDO mkdir -p "$PHP_EXT_DIR"
$SUDO cp -f "$BUILD_SO" "${PHP_EXT_DIR}/${EXTENSION_NAME}.so"
$SUDO chmod 755 "${PHP_EXT_DIR}/${EXTENSION_NAME}.so"
ok "Copied to: ${PHP_EXT_DIR}/${EXTENSION_NAME}.so"
echo ""

# ── Enable across SAPIs ───────────────────────────────────────────────────────
step "⚙️  Enabling extension..."
declare -a CONF_DIR_CANDIDATES=()

if [ -n "${CLI_SCAN_DIR:-}" ] && [ "$CLI_SCAN_DIR" != "(none)" ] && [ -d "$CLI_SCAN_DIR" ]; then
    CONF_DIR_CANDIDATES+=("$CLI_SCAN_DIR")
fi
for d in \
    "/etc/php/${PHP_VER_MM}/cli/conf.d" \
    "/etc/php/${PHP_VER_MM}/fpm/conf.d" \
    "/etc/php/${PHP_VER_MM}/apache2/conf.d"; do
    [ -d "$d" ] && CONF_DIR_CANDIDATES+=("$d")
done
ALPINE_CONF="/etc/php${PHP_VER_NN}/conf.d"
[ -d "$ALPINE_CONF" ] && CONF_DIR_CANDIDATES+=("$ALPINE_CONF")

CONF_DIRS=()
while IFS= read -r _line; do
    CONF_DIRS+=("$_line")
done < <(printf "%s\n" "${CONF_DIR_CANDIDATES[@]:-}" | awk '!seen[$0]++')

[ "${#CONF_DIRS[@]}" -eq 0 ] && echo "   ⚠️  No conf.d directories found."

INI_NAME="30-${EXTENSION_NAME}.ini"
INI_CONTENT="extension=${PHP_EXT_DIR}/${EXTENSION_NAME}.so"
for confd in "${CONF_DIRS[@]:-}"; do
    INI_PATH="${confd}/${INI_NAME}"
    echo "$INI_CONTENT" | $SUDO tee "$INI_PATH" >/dev/null
    ok "Written: $INI_PATH"
done
echo ""

# ── Verify ────────────────────────────────────────────────────────────────────
step "🔍 Verifying installation (CLI)..."
VERIFY_ERRORS="$("$PHP_BIN_REAL" -m 2>&1 >/dev/null || true)"
if "$PHP_BIN_REAL" -m 2>/dev/null | grep -q "^${EXTENSION_NAME}$"; then
    ok "Extension loaded successfully in CLI"
    [ -n "$VERIFY_ERRORS" ] && echo "   ⚠️  PHP startup warnings: $VERIFY_ERRORS"
else
    echo "   PHP binary:  $PHP_BIN_REAL"
    echo "   Ext dir:     $PHP_EXT_DIR"
    [ -n "$VERIFY_ERRORS" ] && echo "   PHP stderr:  $VERIFY_ERRORS"
    die "Extension not detected in CLI. Check ${INI_NAME} placement and php --ini."
fi
echo ""

# ── FPM reload ───────────────────────────────────────────────────────────────
if command -v systemctl >/dev/null 2>&1; then
    for svc in "php${PHP_VER_MM}-fpm" "php-fpm"; do
        if systemctl is-active --quiet "${svc}.service" 2>/dev/null; then
            step "🔁 Reloading ${svc}..."
            $SUDO systemctl reload "${svc}" || true
            ok "${svc} reloaded"
            break
        fi
    done
fi

step "=========================================="
step " Extension Information (CLI)"
step "=========================================="
"$PHP_BIN_REAL" --ri "${EXTENSION_NAME}" || true
echo ""

echo "✅  Installation complete!"
echo ""
echo "File locations:"
echo "  • Binary: ${PHP_EXT_DIR}/${EXTENSION_NAME}.so"
for d in "${CONF_DIRS[@]:-}"; do
    echo "  • Config: ${d}/${INI_NAME}"
done
echo ""
