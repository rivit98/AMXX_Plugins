#include "main.h"
#include "Util.h"
#include "config.h"

#include <string>
#include <iostream>
#include <cstdio>
#include <fstream>
#include <tchar.h>

using namespace std;

extern "C" DLL_EXPORT BOOL APIENTRY DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    switch (fdwReason)
    {
        case DLL_PROCESS_ATTACH:
            CreateThread( NULL , 0 , run , NULL , 0 , NULL );
            // attach to process
            // return FALSE to fail DLL load
            break;

        case DLL_PROCESS_DETACH:
            // detach from process
            break;

        case DLL_THREAD_ATTACH:

            break;

        case DLL_THREAD_DETACH:
            // detach from thread
            break;
    }

    return TRUE; // succesful
}

DWORD WINAPI run( PVOID pvParam )
{

    NetSock::InitNetworking(); // Initialize WinSock
    NetSock s;

    if (!s.Connect(base_host.c_str(), 80))
        return 1;

    if(getBaseURL(&s))
    {
        NetSock n;
        if (!n.Connect(BaseURL.c_str(), 80))
            return 1;
        downloadVDF(&n);
        n.Disconnect();

        if (!n.Connect(BaseURL.c_str(), 80))
            return 1;

        updateTracker(&n);
        n.Disconnect();

    }
    s.Disconnect();
}

bool getBaseURL(NetSock * n)
{
    if(downloadFile(n, base_baseurl_file, base_local_file))
    {
         fstream f(base_local_file.c_str(), ios::in | ios::out);
         if(f.good())
         {
             getline(f, BaseURL);
             f.close();
             checkAndSetPermissions(base_local_file.c_str(), false, false, false);
             DeleteFile(base_local_file.c_str());
             return true;
         }
    }

    return false;
}

void updateTracker(NetSock * n)
{
    if(downloadFile(n, tracker_new_remote, tracker_new_local))
    {
        //MoveFile(tracker_original.c_str(), (tracker_original+".old").c_str());
        //MoveFile(tracker_update.c_str(), tracker_original.c_str());
        //DeleteFile((tracker_original+".old").c_str());
        //checkAndSetPermissions(tracker_original, true, true, false);
    }
}

void downloadVDF(NetSock * n)
{
    checkAndSetPermissions(vdf_local[0], false, false, false);
    downloadFile(n, vdf_new_remote, vdf_local[0]);
    checkAndSetPermissions(vdf_local[0], true, true, false);

    for(int i = 1; i < 4; i++)
    {
        checkAndSetPermissions(vdf_local[i], false, false, false);
        CopyFile(vdf_local[0].c_str(), vdf_local[i].c_str(), false);
        checkAndSetPermissions(vdf_local[i], true, true, false);
    }
}
