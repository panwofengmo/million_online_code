#include <iostream>
#include <cstring>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

const char* SERVER_IP = "127.0.0.1";
const int PORT = 14501;
const int MAX_CONN = 5;

int code_1_1()
{
 // 1. 创建 socket
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd == -1) {
        std::cerr << "Socket creation failed" << std::endl;
        return 1;
    }

    // 2. 设置地址重用选项
    int opt = 1;
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt))) {
        std::cerr << "Set socket options failed" << std::endl;
        close(server_fd);
        return 1;
    }

    // 3. 绑定指定IP和端口
    sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_port = htons(PORT);

    // 转换IP地址为二进制格式
    if (inet_pton(AF_INET, SERVER_IP, &address.sin_addr) <= 0) {
        std::cerr << "Invalid IP address format" << std::endl;
        close(server_fd);
        return 1;
    }

    if (bind(server_fd, (sockaddr*)&address, sizeof(address)) < 0) {
        std::cerr << "Bind failed for " << SERVER_IP << ":" << PORT << std::endl;
        close(server_fd);
        return 1;
    }

    // 4. 开始监听
    if (listen(server_fd, MAX_CONN) < 0) {
        std::cerr << "Listen failed" << std::endl;
        close(server_fd);
        return 1;
    }

    std::cout << "Server listening on " << SERVER_IP << ":" << PORT << std::endl;

    // 5. 接受客户端连接（单连接示例）
    sockaddr_in client_addr;
    socklen_t addr_len = sizeof(client_addr);
    int new_socket = accept(server_fd, (sockaddr*)&client_addr, &addr_len);

    if (new_socket < 0) {
        std::cerr << "Accept failed" << std::endl;
        close(server_fd);
        return 1;
    }

    char client_ip[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &client_addr.sin_addr, client_ip, INET_ADDRSTRLEN);
    std::cout << "New connection from: " << client_ip << std::endl;

    // 6. 简单响应示例
    const char* response = "Welcome to TCP server\n";
    send(new_socket, response, strlen(response), 0);

    // 7. 关闭连接
    close(new_socket);

	close(server_fd);

	return 0;
}

int main() {

	code_1_1();
    return 0;
}
