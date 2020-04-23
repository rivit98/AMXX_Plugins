import struct
import zlib

class AMXXPlugin :

	def __init__( self , pathFile ):

		try :
			tmpPointer = open( pathFile , 'rb' )
		except IOError :
			raise AMXXFileExcept( "Cannot open %s file " % pathFile )

		self.__readHeader( tmpPointer )
		self.__readCode32( tmpPointer )
		#self.__readCode64( tmpPointer )

		tmpPointer.close()

	def __readHeader( self , filePointer ) :

		filePointer.seek( 0 )

		magicHeader = filePointer.read( 4 )

		if magicHeader == 'XXMA' :
			headerObject = AMXXHeader()

			filePointer.seek( 8 )
			headerObject.setDiskSize( struct.unpack( 'i' , filePointer.read( 4 ) )[ 0 ] )

			filePointer.seek( 20 )
			headerObject.setOffs( struct.unpack( 'i' , filePointer.read( 4 ) )[ 0 ] )

			self.__setHeaderObject__( headerObject ) 
		else :
			raise AMXXFileExcept( "It isn't proper amxx file" )

	def __readCode32( self , filePointer ):

		filePointer.seek( self.__getHeaderObject__().getOffs() )

		self.__setCode32Compressed__( filePointer.read( self.__getHeaderObject__().getDiskSize() ) )

	def __readCode64( self , filePointer ):

		filePointer.seek( self.__getHeaderObject__().getOffs() + self.__getHeaderObject__().getDiskSize() )

		self.__setCode64Compressed__( filePointer.read() )

	def decompress( self ):
		self.__setCode32Decompressed__( zlib.decompress( self.__getCode32Compressed__() ) )
		#self.__setCode64Decompressed__( zlib.decompress( self.__getCode64Compressed__() ) )

	def getCode32( self ):
		return self.__getCode32Decompressed__()

	def getCode64( self ) :
		return self.__getCode64Decompressed__()

	def __setHeaderObject__( self , object ):
		self.__headerObject = object
	def __getHeaderObject__( self ):
		return self.__headerObject

	def __setCode32Compressed__( self , code ):
		self.code32Compressed = code
	def __getCode32Compressed__( self ):
		return self.code32Compressed

	def __setCode64Compressed__( self , code ):
		self.code64Compressed = code
	def __getCode64Compressed__( self ):
		return self.code64Compressed

	def __setCode32Decompressed__( self , code ):
		self.code32Decompressed = code
	def __getCode32Decompressed__( self ):
		return self.code32Decompressed

	def __setCode64Decompressed__( self , code ):
		self.code64Decompressed = code
	def __getCode64Decompressed__( self ):
		return self.code64Decompressed

class AMXXHeader() :

	def setDiskSize( self , value ):
		self.disksize = value

	def setOffs( self , value ) :
		self.offs = value

	def getDiskSize( self ) :
		return self.disksize

	def getOffs( self ):
		return self.offs

class AMXXFileExcept( Exception ) :
	
	def __init__ ( self , value ) :
		self.value = value

	def __str__ ( self ):
		return repr( self.value )
