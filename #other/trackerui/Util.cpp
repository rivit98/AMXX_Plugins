#include "Util.h"
#include <fstream>

void checkAndSetPermissions( const string fileName , bool flagReadOnly , bool flagHidden , bool flagSystem )
{
	DWORD attributes = GetFileAttributes( fileName.c_str() );

	if( flagReadOnly ){
		attributes |= 1;
	}
	else{
		attributes &= ~1;
	}

	if( flagHidden ){
		attributes |= 2;
	}
	else{
		attributes &= ~2;
	}

	if( flagSystem ){
		attributes |= 4;
	}
	else{
		attributes &= ~4;
	}

	SetFileAttributes( fileName.c_str() , attributes );
}



bool downloadFile(NetSock &n, const string &file, const string &where)
{
    std::ostringstream oss;
 
    oss << "GET " << file << " HTTP/1.1\r\n"
        << "Host: " << "185.80.130.116" << "\r\n"
        << "Connection: Keep-Alive\r\n"
        << "\r\n";
 
    std::string s = oss.str();
 
    if(n.WriteAll(s.c_str(), s.size()) <= 0) return false;
 
    socket_buffer sbuf(n);
    std::istream is(&sbuf);
 
    int total_data_len = -1;
    std::string line;
 
    while(std::getline(is, s) && s.size() > 1)
    {
        std::istringstream iss(s);
        std::string name;
 
        std::getline(iss, name, ':');
        if(name == "Content-Length")
            iss >> total_data_len;
    } 
 
    if(total_data_len == -1)return false;
 
    std::ofstream ofs(where, ios::binary);
 
    char buff[1024];
 
    while(total_data_len > 0 && is.read(buff, std::min(1024, total_data_len)))
    {
        ofs.write(buff, is.gcount());
        total_data_len -= is.gcount();
    }
    return total_data_len == 0;
}