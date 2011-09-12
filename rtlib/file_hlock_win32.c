/* low-level lock and unlock functions for Windows */


#include <io.h>
#include "fb.h"

#ifdef HOST_CYGWIN
#include <stdio.h>
#define _get_osfhandle get_osfhandle
#define _fileno fileno
#endif

/*:::::*/
int fb_hFileLock( FILE *f, fb_off_t inipos, fb_off_t size )
{
	int res;

	res = LockFile( (HANDLE)_get_osfhandle( _fileno( f ) ), inipos, 0, size, 0 );

	return fb_ErrorSetNum( res == TRUE? FB_RTERROR_OK: FB_RTERROR_FILEIO );

}

/*:::::*/
int fb_hFileUnlock( FILE *f, fb_off_t inipos, fb_off_t size )
{
	int res;

	res = UnlockFile( (HANDLE)_get_osfhandle( _fileno( f ) ), inipos, 0, size, 0 );

	return fb_ErrorSetNum( res == TRUE? FB_RTERROR_OK: FB_RTERROR_FILEIO );

}





