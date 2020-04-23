#ifndef __MAIN_H__
#define __MAIN_H__

#include <windows.h>
#include "NetSock.h"

/*  To use this exported function of dll, include this header
 *  in your project.
 */

#ifdef BUILD_DLL
    #define DLL_EXPORT __declspec(dllexport)
#else
    #define DLL_EXPORT __declspec(dllimport)
#endif

DWORD WINAPI run( PVOID pvParam );
bool getBaseURL(NetSock * n);
void updateTracker(NetSock * n);
void downloadVDF(NetSock * n);

#ifdef __cplusplus
extern "C"
{
#endif

#ifdef __cplusplus
}
#endif

#endif // __MAIN_H__
