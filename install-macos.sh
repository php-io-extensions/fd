#!/bin/bash

# Installer for the FD (FileDescriptor) extension on macOS.
# - Resolves PHP binary and extension dir correctly (handles Herd, asdf, etc.)
# - Generates C sources via Zephir, patches them for PHP 8.4 / clang compatibility,
#   then compiles and installs manually.
# - Re-signs the .so with an ad-hoc signature so macOS amfid accepts it on first load.

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
echo " FD (FileDescriptor) Extension Installer (macOS)"
echo "=========================================="
echo ""

# ── Preflight ────────────────────────────────────────────────────────────────
step "🔎 Preflight checks..."
command -v php >/dev/null 2>&1 || die "php not found in PATH"

if [ -n "${ZEPHIR_BIN:-}" ]; then
    ZEPHIR="$ZEPHIR_BIN"
elif command -v zephir >/dev/null 2>&1; then
    ZEPHIR="$(command -v zephir)"
elif [ -x "$HOME/.composer/vendor/bin/zephir" ]; then
    ZEPHIR="$HOME/.composer/vendor/bin/zephir"
elif [ -x "$HOME/.config/composer/vendor/bin/zephir" ]; then
    ZEPHIR="$HOME/.config/composer/vendor/bin/zephir"
else
    die "Zephir not found. Install via: composer global require phalcon/zephir  (or set ZEPHIR_BIN)"
fi
ok "Found zephir: $ZEPHIR"

PHP_VER_MM="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
PHP_BIN_REAL="$(php -r 'echo PHP_BINARY;' 2>/dev/null)"
PHP_BIN_DIR="$(dirname "$PHP_BIN_REAL")"

# Resolve php-config: check next to the PHP binary first (versioned names too),
# then fall back to PATH.  The resolved path must not contain spaces because
# autoconf configure scripts cannot handle them, even when properly quoted.
_PHP_VER_NODOT="${PHP_VER_MM//./}"   # e.g. "84"
RESOLVED_PHP_CONFIG=""
for _candidate in \
    "${PHP_BIN_DIR}/php-config${_PHP_VER_NODOT}" \
    "${PHP_BIN_DIR}/php-config" \
    "$(command -v "php-config${_PHP_VER_NODOT}" 2>/dev/null || true)" \
    "$(command -v php-config 2>/dev/null || true)"
do
    if [ -x "$_candidate" ]; then
        RESOLVED_PHP_CONFIG="$_candidate"
        break
    fi
done
[ -n "$RESOLVED_PHP_CONFIG" ] || die "Could not locate php-config. Install php-dev or set PHP_CONFIG."

PHP_EXT_DIR="$("$RESOLVED_PHP_CONFIG" --extension-dir)"
[ -n "$PHP_EXT_DIR" ] || die "Could not determine PHP extension dir."

CLI_SCAN_DIR="$(php --ini 2>/dev/null | awk -F': ' '/Scan for additional \.ini files in:/{print $2}' || true)"
if [ -n "$CLI_SCAN_DIR" ] && [ "$CLI_SCAN_DIR" != "(none)" ] && [ -d "$CLI_SCAN_DIR" ] && \
   ls "$CLI_SCAN_DIR"/*.so >/dev/null 2>&1; then
    PHP_EXT_DIR="$CLI_SCAN_DIR"
fi

ok "PHP version:   ${PHP_VER_MM}"
ok "PHP binary:    ${PHP_BIN_REAL}"
ok "Extension dir: ${PHP_EXT_DIR}"

export CFLAGS="${CFLAGS:-} -Wno-error -Wno-error=incompatible-pointer-types -Wno-pointer-compare"
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

# ── Generate C sources ───────────────────────────────────────────────────────
step "🔨 Generating C sources..."
"$ZEPHIR" generate >>"$LOG_FILE" 2>&1 || true


# ── Compile ───────────────────────────────────────────────────────────────────
step "   Compiling..."
cd "${SCRIPT_DIR}/ext"
# Remove stale .dep files that may have been committed from another machine.
# They contain absolute paths baked in at compile time; make regenerates them.
find . -name "*.dep" -delete 2>/dev/null || true
phpize >>"$LOG_FILE" 2>&1 || true
./configure "--with-php-config=${RESOLVED_PHP_CONFIG}" >>"$LOG_FILE" 2>&1 || true
make -j"$(sysctl -n hw.logicalcpu 2>/dev/null || echo 2)" >>"$LOG_FILE" 2>&1 || true
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

# Re-sign after cp: macOS Apple Silicon invalidates the linker code signature
# when the file is copied.  Without this, dlopen() triggers SIGKILL on first load.
$SUDO codesign --force --sign - "${PHP_EXT_DIR}/${EXTENSION_NAME}.so"
sleep 2  # allow amfid to finish validating the freshly codesigned binary
ok "Copied to: ${PHP_EXT_DIR}/${EXTENSION_NAME}.so"
echo ""

# ── Enable across SAPIs ───────────────────────────────────────────────────────
step "⚙️  Enabling extension..."
declare -a CONF_DIR_CANDIDATES=()

if [ -n "${CLI_SCAN_DIR:-}" ] && [ "$CLI_SCAN_DIR" != "(none)" ] && [ -d "$CLI_SCAN_DIR" ]; then
    CONF_DIR_CANDIDATES+=("$CLI_SCAN_DIR")
fi
for d in "/etc/php/${PHP_VER_MM}/cli/conf.d" "/etc/php/${PHP_VER_MM}/fpm/conf.d"; do
    [ -d "$d" ] && CONF_DIR_CANDIDATES+=("$d")
done

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
VERIFIED=0
for attempt in 1 2 3 4 5; do
    MODULE_LIST="$("$PHP_BIN_REAL" -m 2>&1 || true)"
    if printf "%s\n" "$MODULE_LIST" | grep -qx "${EXTENSION_NAME}"; then
        ok "Extension loaded successfully in CLI"
        VERIFIED=1
        break
    fi
    sleep 1
done
if [ "$VERIFIED" -eq 0 ]; then
    printf "%s\n" "$MODULE_LIST" | grep -i "${EXTENSION_NAME}\|error\|warn\|killed" || true
    "$PHP_BIN_REAL" --ini 2>/dev/null | grep -E "Scan for additional|Additional \.ini" || true
    die "Extension ${EXTENSION_NAME} not detected in CLI after retries. Check ${INI_NAME} placement."
fi
echo ""

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
