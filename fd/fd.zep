namespace Fd;

class FD
{
    public static function open(var device_path, int flags) -> int
    {
        int result;
        string dp = device_path;

        let result = open_file(dp, flags);

        return result;
    }

    public static function close(int _fd) -> int
    {
        int result;

        let result = close_fd(_fd);

        return result;
    }

    public static function addFlags(int _fd, int flags) -> int
    {
        int result;

        let result = add_fd_flags(_fd, flags);

        return result;
    }

    public static function read(int fd, int bytes_to_read) -> string
    {
        var result;

        let result = read_fd(fd, bytes_to_read);

        return result;
    }

    public static function write(int fd, var data, int bytes_to_write) -> int
    {
        int results;
        string payload = data;

        let results = write_fd(fd, payload, bytes_to_write);

        return results;
    }
}