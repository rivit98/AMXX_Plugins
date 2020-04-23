# -*- coding: utf-8 -*-
#! /usr/bin/env python

import sys
import os

from AMXXPlugin import *

def writeToFile( fileName , data ) :
	try :
		tmpPointer = open( fileName , "wb" )
	except IOError :
		print "Canno't save to %s" % fileName
	else :
		tmpPointer.write( data )

	tmpPointer.close()

if __name__ == "__main__" :
	
	for argPath in sys.argv[ 1: ] :
		try :
			objectPlugin = AMXXPlugin( argPath )
		except AMXXFileExcept as currentExcept :
			print currentExcept.value
			continue
		else :
			objectPlugin.decompress();
			
			fileName , fileExtension = os.path.splitext( argPath )

			writeToFile( fileName + "decCode32.txt" , objectPlugin.getCode32() )
			writeToFile( fileName + "decCode64.txt" , objectPlugin.getCode64() )


