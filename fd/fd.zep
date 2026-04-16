namespace Fd;

%{
#include <fcntl.h>
#include <unistd.h>
}%
class FD
{
    public static function open(string device_path, int flags) -> int
    {
        int result;
        var dp = device_path;

        %{
            result = open(Z_STRVAL_P(&dp), (int) flags);
        }%


        return result;
    }

    public static function close(int _fd) -> int
    {
        int result;

        %{
            result = close((int) _fd);
        }%

        return result;
    }

    public static function addFlags(int _fd, int flags) -> int
    {
        int result;

        %{
            int current_flags;
            
            // Get current file descriptor flags
            current_flags = fcntl(_fd, F_GETFL, 0);
            
            if (current_flags < 0) {
                result = -1;
            } else {
                // OR in the new flags and set them
                result = fcntl(_fd, F_SETFL, current_flags | flags);
            }
        }%

        return result;
    }

    public static function read(int fd, int bytes_to_read) -> string
    {
        var result;

        %{
            char *_buf = emalloc((size_t) bytes_to_read + 1);
            ssize_t _n = read((int) fd, _buf, (size_t) bytes_to_read);

            if (_n < 0) {
                efree(_buf);
                ZVAL_EMPTY_STRING(&result);
            } else {
                _buf[_n] = '\0';
                ZVAL_STRINGL(&result, _buf, (size_t) _n);
                efree(_buf);
            }
        }%

        return result;
    }

    public static function write(int fd, string data, int bytes_to_write) -> int
    {
        int results;

        %{
            results = (zend_long) write((int) fd, (const char *) Z_STRVAL(data), (size_t) bytes_to_write);
        }%

        return results;
    }
}