/* BELDE native messaging host. No third-party runtime or credential storage.
 * Build POSIX: cc -std=c11 -O2 -Wall -Wextra -Werror belde_host.c -o bin/belde_host
 * Build Windows: x86_64-w64-mingw32-gcc -std=c11 -O2 -Wall -Wextra -Werror
 *                belde_host.c -o bin/belde_host.exe -lws2_32
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <io.h>
#include <fcntl.h>
typedef SOCKET socket_handle;
#define INVALID_HANDLE INVALID_SOCKET
#define close_socket closesocket
#else
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include <time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <arpa/inet.h>
typedef int socket_handle;
#define INVALID_HANDLE (-1)
#define close_socket close
#endif

#define MAX_REQUEST 65536U
#define MAX_RESPONSE (1024U * 1024U)
#define MAX_HEADER 16384U
#define DEFAULT_PORT 43127

static uint64_t millis(void) {
#ifdef _WIN32
    return (uint64_t)GetTickCount64();
#else
    struct timespec t;
    if (clock_gettime(CLOCK_MONOTONIC, &t) != 0) return 0;
    return (uint64_t)t.tv_sec * 1000U + (uint64_t)t.tv_nsec / 1000000U;
#endif
}

static int transient_error(void) {
#ifdef _WIN32
    int e = WSAGetLastError();
    return e == WSAEWOULDBLOCK || e == WSAEINPROGRESS || e == WSAEINTR;
#else
    return errno == EAGAIN || errno == EWOULDBLOCK || errno == EINPROGRESS || errno == EINTR;
#endif
}

static int wait_socket(socket_handle s, int writing, uint64_t deadline) {
    for (;;) {
        uint64_t now = millis();
        if (now >= deadline) return 0;
        uint64_t left = deadline - now;
        struct timeval timeout;
        timeout.tv_sec = (long)(left / 1000U);
        timeout.tv_usec = (long)((left % 1000U) * 1000U);
        fd_set set;
        FD_ZERO(&set);
        FD_SET(s, &set);
        int r = select((int)s + 1, writing ? NULL : &set,
                       writing ? &set : NULL, NULL, &timeout);
        if (r > 0) return 1;
        if (r == 0 || !transient_error()) return 0;
    }
}

static int make_nonblocking(socket_handle s) {
#ifdef _WIN32
    u_long yes = 1;
    return ioctlsocket(s, FIONBIO, &yes) == 0;
#else
    int old = fcntl(s, F_GETFL, 0);
    return old >= 0 && fcntl(s, F_SETFL, old | O_NONBLOCK) == 0;
#endif
}

static socket_handle connect_game(int port) {
    socket_handle s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (s == INVALID_HANDLE) return INVALID_HANDLE;
    if (!make_nonblocking(s)) { close_socket(s); return INVALID_HANDLE; }
    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_port = htons((unsigned short)port);
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    int connected = connect(s, (struct sockaddr *)&address, sizeof(address));
    if (connected != 0) {
        if (!transient_error() || !wait_socket(s, 1, millis() + 2000U)) {
            close_socket(s); return INVALID_HANDLE;
        }
        int error = 0;
#ifdef _WIN32
        int n = sizeof(error);
        if (getsockopt(s, SOL_SOCKET, SO_ERROR, (char *)&error, &n) != 0 || error != 0) {
#else
        socklen_t n = sizeof(error);
        if (getsockopt(s, SOL_SOCKET, SO_ERROR, &error, &n) != 0 || error != 0) {
#endif
            close_socket(s); return INVALID_HANDLE;
        }
    }
    return s;
}

static int send_all(socket_handle s, const unsigned char *bytes, size_t length,
                    uint64_t deadline) {
    size_t sent = 0;
    while (sent < length) {
        if (!wait_socket(s, 1, deadline)) return 0;
        size_t remain = length - sent;
        int count = (int)(remain > INT_MAX ? INT_MAX : remain);
        int n = send(s, (const char *)bytes + sent, count, 0);
        if (n > 0) sent += (size_t)n;
        else if (n == 0 || !transient_error()) return 0;
    }
    return 1;
}

static int same_name(const char *start, size_t length, const char *wanted) {
    size_t i;
    if (strlen(wanted) != length) return 0;
    for (i = 0; i < length; ++i)
        if (tolower((unsigned char)start[i]) != tolower((unsigned char)wanted[i])) return 0;
    return 1;
}

/* Parse Content-Length strictly. Chunked/redirect bodies are never followed. */
static int body_length(char *header, size_t length, size_t *out) {
    char *line = strstr(header, "\r\n");
    int code = 0, found = 0;
    if (!line || sscanf(header, "HTTP/%*d.%*d %d", &code) != 1 || code < 100 || code > 599)
        return 0;
    line += 2;
    while ((size_t)(line - header) < length && *line) {
        char *end = strstr(line, "\r\n");
        if (!end) return 0;
        if (end == line) break;
        char *colon = memchr(line, ':', (size_t)(end - line));
        if (!colon) return 0;
        if (same_name(line, (size_t)(colon - line), "transfer-encoding")) return 0;
        if (same_name(line, (size_t)(colon - line), "content-length")) {
            if (found) return 0;
            char *value = colon + 1;
            while (value < end && (*value == ' ' || *value == '\t')) ++value;
            if (value == end || !isdigit((unsigned char)*value)) return 0;
            size_t number = 0;
            while (value < end && isdigit((unsigned char)*value)) {
                unsigned int digit = (unsigned int)(*value++ - '0');
                if (number > (MAX_RESPONSE - digit) / 10U) return 0;
                number = number * 10U + digit;
            }
            while (value < end && (*value == ' ' || *value == '\t')) ++value;
            if (value != end || number == 0 || number > MAX_RESPONSE) return 0;
            *out = number;
            found = 1;
        }
        line = end + 2;
    }
    return found;
}

static const char *forward(int port, const unsigned char *request, size_t length,
                           unsigned char **response, size_t *response_length) {
    socket_handle s = connect_game(port);
    if (s == INVALID_HANDLE) return "Start Belde before connecting the editor.";
    char header[256];
    int head_length = snprintf(header, sizeof(header),
        "POST /native HTTP/1.1\r\nHost: 127.0.0.1:%d\r\n"
        "Content-Type: application/json\r\nContent-Length: %lu\r\nConnection: close\r\n\r\n",
        port, (unsigned long)length);
    uint64_t deadline = millis() + 5000U;
    if (head_length <= 0 || (size_t)head_length >= sizeof(header) ||
        !send_all(s, (const unsigned char *)header, (size_t)head_length, deadline) ||
        !send_all(s, request, length, deadline)) {
        close_socket(s); return "Belde did not accept the editor message.";
    }
    unsigned char *buffer = (unsigned char *)malloc(MAX_HEADER + MAX_RESPONSE + 1U);
    if (!buffer) { close_socket(s); return "The editor host could not allocate its response buffer."; }
    size_t used = 0, offset = 0, body = 0;
    int parsed = 0;
    while (used < MAX_HEADER + MAX_RESPONSE) {
        if (!wait_socket(s, 0, deadline)) break;
        size_t capacity = MAX_HEADER + MAX_RESPONSE - used;
        int n = recv(s, (char *)buffer + used, (int)capacity, 0);
        if (n < 0 && transient_error()) continue;
        if (n <= 0) break;
        used += (size_t)n;
        buffer[used] = 0;
        if (!parsed) {
            char *end = strstr((char *)buffer, "\r\n\r\n");
            if (end) {
                offset = (size_t)(end - (char *)buffer) + 4U;
                if (offset > MAX_HEADER || !body_length((char *)buffer, offset, &body)) break;
                parsed = 1;
            } else if (used >= MAX_HEADER) break;
        }
        if (parsed && used - offset >= body) {
            size_t first = offset, last = offset + body;
            while (first < last && isspace(buffer[first])) ++first;
            while (last > first && isspace(buffer[last - 1U])) --last;
            /* The trusted game returns JSON objects. Reject an HTML error page. */
            if (first == last || buffer[first] != '{' || buffer[last - 1U] != '}') break;
            memmove(buffer, buffer + offset, body);
            buffer[body] = 0;
            *response = buffer;
            *response_length = body;
            close_socket(s);
            return NULL;
        }
    }
    free(buffer);
    close_socket(s);
    return "Belde returned an incomplete or unsupported editor response. Reconnect and try again.";
}

static int output_frame(const unsigned char *bytes, size_t length) {
    unsigned char prefix[4];
    prefix[0] = (unsigned char)(length & 255U);
    prefix[1] = (unsigned char)((length >> 8U) & 255U);
    prefix[2] = (unsigned char)((length >> 16U) & 255U);
    prefix[3] = (unsigned char)((length >> 24U) & 255U);
    if (fwrite(prefix, 1, 4, stdout) != 4 || fwrite(bytes, 1, length, stdout) != length)
        return 0;
    return fflush(stdout) == 0;
}

/* All error strings are fixed literals, never contain tokens or request content. */
static int output_error(const char *message) {
    char buffer[512];
    int n = snprintf(buffer, sizeof(buffer),
        "{\"ok\":false,\"status\":\"disconnected\",\"message\":\"%s\"}", message);
    return n > 0 && (size_t)n < sizeof(buffer) &&
           output_frame((const unsigned char *)buffer, (size_t)n);
}

static int read_exact(unsigned char *bytes, size_t length) {
    size_t read_count = 0;
    while (read_count < length) {
        size_t n = fread(bytes + read_count, 1, length - read_count, stdin);
        if (n == 0) return read_count == 0 && feof(stdin) ? 0 : -1;
        read_count += n;
    }
    return 1;
}

int main(void) {
#ifdef _WIN32
    WSADATA data;
    if (WSAStartup(MAKEWORD(2, 2), &data) != 0) return 1;
    _setmode(_fileno(stdin), _O_BINARY);
    _setmode(_fileno(stdout), _O_BINARY);
#else
    signal(SIGPIPE, SIG_IGN);
#endif
    int port = DEFAULT_PORT;
    const char *configured = getenv("BELDE_BRIDGE_PORT");
    if (configured && *configured) {
        char *end = NULL;
        long value = strtol(configured, &end, 10);
        if (!end || *end || value < 1024 || value > 65535) {
            output_error("BELDE_BRIDGE_PORT must be an integer from 1024 to 65535.");
            return 1;
        }
        port = (int)value;
    }
    for (;;) {
        unsigned char prefix[4];
        int status = read_exact(prefix, 4);
        if (status == 0) break;
        if (status < 0) { output_error("The native message length was incomplete."); return 1; }
        uint32_t length = (uint32_t)prefix[0] | ((uint32_t)prefix[1] << 8U) |
                          ((uint32_t)prefix[2] << 16U) | ((uint32_t)prefix[3] << 24U);
        if (length == 0 || length > MAX_REQUEST) {
            output_error("Native editor messages must contain 1 to 65536 bytes."); return 1;
        }
        unsigned char *request = (unsigned char *)malloc((size_t)length + 1U);
        if (!request) { output_error("The editor host could not allocate its request buffer."); return 1; }
        if (read_exact(request, length) != 1) {
            free(request); output_error("The native editor message was incomplete."); return 1;
        }
        request[length] = 0;
        unsigned char *response = NULL;
        size_t response_length = 0;
        const char *error = forward(port, request, length, &response, &response_length);
        free(request);
        int written = error ? output_error(error) : output_frame(response, response_length);
        free(response);
        if (!written) return 1;
    }
#ifdef _WIN32
    WSACleanup();
#endif
    return 0;
}
