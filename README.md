# FD

[![PHP][badge-php]][php]
[![Zephir][badge-zephir]][zephir-install]
[![Platform][badge-platform]][linux]

PHP-controllable UNIX file descriptor extension built with Zephir.

The FD extension allows PHP to open raw UNIX file descriptors, enabling control beyond simple stream-based I/O. The integer descriptor can be passed into other extensions or used directly for system-level interfaces such as GPIO, I2C, SPI, and UART.

## Requirements

- PHP 8.x
- A UNIX-like operating system (Linux, macOS)
- Standard C build tools (`gcc`, `make`, PHP development headers)

## Installation

### Via PHP PIE (recommended)

[PHP PIE](https://github.com/php/pie) is the official PHP extension installer. It handles the full build and activation pipeline automatically.

Install PIE if you haven't already:

```shell
curl -Lo pie.phar https://github.com/php/pie/releases/latest/download/pie.phar
chmod +x pie.phar
sudo mv pie.phar /usr/local/bin/pie
```

Then install the extension:

```shell
pie install php-io-extensions/fd
```

PIE will build the extension from source, copy the `.so` into PHP's extension directory, and write the ini activation file. No Zephir required — the C source is pre-generated in the package.

### Manual installation

Clone the repository and run the bundled installer script. PHP dev headers and `gcc` must be present; Zephir is **not** required.

```shell
git clone https://github.com/php-io-extensions/fd
cd fd
bash install.sh
```

The script builds from the pre-generated C source in `ext/`, installs the `.so`, and enables the extension across all detected SAPIs (CLI, FPM, Apache).

### Verifying installation

```shell
php -m | grep fd
php --ri fd
```

## Usage

All methods are static on the `Fd\FD` class.

### Flags

`$flags` parameters accept plain integers. They map directly to the POSIX constants from `fcntl.h` — PHP does not define these, so pass the values directly or define your own:

| Constant | Linux | macOS |
|----------|-------|-------|
| `O_RDONLY` | `0` | `0` |
| `O_WRONLY` | `1` | `1` |
| `O_RDWR` | `2` | `2` |
| `O_NONBLOCK` | `2048` | `4` |

Combine multiple flags with the bitwise OR operator (`|`):

```php
// O_WRONLY | O_NONBLOCK on Linux
$fd = Fd\FD::open('/dev/ttyUSB0', 1 | 2048);
```

---

### `FD::open`

Opens a file or device and returns a file descriptor integer.

```php
$fd = Fd\FD::open(string $device_path, int $flags): int
```

Returns the file descriptor on success, or a negative value on failure.

```php
// Open an I2C device for reading and writing (O_RDWR = 2)
$fd = Fd\FD::open('/dev/i2c-1', 2);

if ($fd < 0) {
    throw new RuntimeException("Failed to open device");
}
```

---

### `FD::close`

Closes an open file descriptor.

```php
$result = Fd\FD::close(int $fd): int
```

Returns `0` on success, `-1` on failure.

```php
Fd\FD::close($fd);
```

---

### `FD::addFlags`

Adds file status flags to an open file descriptor using `fcntl`. Existing flags are preserved; the provided flags are OR'd in.

```php
$result = Fd\FD::addFlags(int $fd, int $flags): int
```

Returns `0` on success, `-1` on failure. Useful for setting a descriptor non-blocking after it has already been opened.

```php
// Set O_NONBLOCK on an open descriptor (Linux: 2048, macOS: 4)
Fd\FD::addFlags($fd, 2048);

// Combine flags: O_NONBLOCK | O_APPEND on Linux
Fd\FD::addFlags($fd, 2048 | 1024);
```

---

### `FD::read`

Reads up to `$bytes_to_read` bytes from a file descriptor and returns them as a string.

```php
$data = Fd\FD::read(int $fd, int $bytes_to_read): string
```

Returns the bytes read as a binary string. Returns an empty string on error. A zero-length read (e.g. EOF) also returns an empty string, so callers that need to distinguish the two cases should check the descriptor state beforehand.

```php
// Read 2 bytes from a UART device
$bytes = Fd\FD::read($fd, 2);
```

---

### `FD::write`

Writes bytes to a file descriptor.

```php
$written = Fd\FD::write(int $fd, string $data, int $bytes_to_write): int
```

Returns the number of bytes written on success, or `-1` on failure.

```php
// Send a command byte over SPI
Fd\FD::write($fd, "\x3A", 1);
```

---

## Example: I2C Read/Write

```php
// O_RDWR = 2
$fd = Fd\FD::open('/dev/i2c-1', 2);

if ($fd < 0) {
    throw new RuntimeException('Could not open I2C device');
}

// Write a register address
Fd\FD::write($fd, "\x00", 1);

// Read 2 bytes back
$data = Fd\FD::read($fd, 2);

Fd\FD::close($fd);
```

## License

Project Saturn Studios, LLC.

[badge-php]: https://img.shields.io/badge/php-%3E%3D8.3-blue
[badge-zephir]: https://img.shields.io/badge/zephir-0.19%2B-orange
[badge-platform]: https://img.shields.io/badge/platform-linux%20%7C%20macos-lightgrey
[php]: https://www.php.net
[zephir-install]: https://docs.zephir-lang.com/latest/en/installation
[linux]: https://www.kernel.org
