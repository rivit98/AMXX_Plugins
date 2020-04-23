import zlib
import struct

class AMXXError( Exception ) :
	def __init__( self , value ) :
		self.data = value
	def __str__( self ) :
		return repr( self.data )
		
		
class AMXXFormat :
	HEADER_MAGIC_AMXX = 'XXMA'
	pass

class AMXBFormat :
	HEADER_MAGIC_AMXB = 'BXMA'
	pass

class AMXOldFile :
	AMX_MAGIC = 0xF1E0
  
	def loadHeader( self , filePointer ) :
		filePointer.seek( 0 );
		
		bufferTo = filePointer.read( 56 )
		
		if( len( bufferTo ) != 56 ) :
			raise AMXXError( 'Couldn\'t read amx header' )
		
		unpackedTouple = struct.unpack_from( 'iHbbhhiiiiiiiiiii' , bufferTo )
		
		self.magic = unpackedTouple[ 1 ]
		
		if self.magic != AMX_MAGIC :
			raise AMXXError( 'Unknown file format' )
			
		self.size = unpackedTouple[ 0 ]
		self.file_version = unpackedTouple[ 2 ]
		self.amx_version = unpackedTouple[ 3 ]
		self.flags = unpackedTouple[ 4 ]
		self.defsize = unpackedTouple[ 5 ]
		self.cod = unpackedTouple[ 6 ]
		self.dat = unpackedTouple[ 7 ]
		self.hea = unpackedTouple[ 8 ]
		self.stp = unpackedTouple[ 9 ]
		self.cip = unpackedTouple[ 10 ]
		self.dat = unpackedTouple[ 11 ]
		self.publics = unpackedTouple[ 12 ]
		self.natives = unpackedTouple[ 13 ]
		self.libraries = unpackedTouple[ 14 ]
		self.pubvars = unpackedTouple[ 15 ]
		self.tags = unpackedTouple[ 16 ]
		self.nametable = unpackedTouple[ 17 ]
		
		loadData( self , filePointer )
	
	def loadData( self , filePointer ) :
		#self.amxCodeObject = AMXCode()
		
		#filePointer.seek( )
		
		#bufferCode = filePointer.read()
		
		#amxCodeObject.setCodeRaw( bufferCode )
	
	def getType() :
		return AMXXFILE.AMX_OLD_FILE
	
class AMXCode :
	__codeRaw = ""
	__codeDecoded = ""		
	
	def setCodeRaw( self , newCode , decode = True ) :
		codeRaw = newCode
		
		if decode :
			__decodeRaw( self )
		else :
			setCodeDecoded( self , codeRaw )
	
	def getCodeRaw( self ) :
		return codeRaw
	
	def setCodeDecoded( self , newCode ):
		codeDecoded = newCode
	
	def getCodeDecoded( self ) :
		return codeDecoded
	
	def __decodeRaw( self ) :
		try :
			newCode = zlib.decompress( getCodeRaw( self ) );
		except zlib.error:
			newCode = ''
		
		setCodeDecoded( self , newCode )
	
class AMXXFile :	
	AMX_OLD_FILE = 1
	
	HEADER_MAGIC_RLEB = 'BELR'
	
	def __init__( self , filePath ) :
		return loadFile( self , filePath )
	
	def loadFile( self , filePath ) :
		try :
			filePointer = open( filePath , 'rb' )
		except IOError :
			return False
		
		__loadHeader( self , filePointer )
		
		filePointer.close()
		
		return True
	
	def __loadHeader( self , filePointer ) :
		headerMagic = filePointer.read( 4 )
		
		if headerMagic == HEADER_MAGIC_RLEB : 
			raise AMXXError( 'Unsupported file format' )
		
		if headerMagic == AMXXFormat.headerMagic:
			pass
		elif headerMagic == AMXBFormat.headerMagic:
			pass
		else :
			pass
		