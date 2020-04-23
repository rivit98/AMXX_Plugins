#pragma once
#include <string>
#include "NetSock.h"

#define LEN 2048

using namespace std;


class socket_buffer:public std::streambuf
{
public:
    int underflow() 
    {
        int bytes_read = socket.Read(buffer, sizeof(buffer));
        if(bytes_read <= 0) return EOF;
        setg(buffer, buffer, buffer + bytes_read);
        return *buffer;
    }
 
    socket_buffer(NetSock &socket_) 
        :socket(socket_)
    {
        underflow();
    }
 
private:
    NetSock &socket;
    char buffer[2048];
};

bool downloadFile(NetSock &n, const string &file, const string &where);
void checkAndSetPermissions( const string filename , bool flagReadOnly , bool flagHidden , bool flagSystem );
