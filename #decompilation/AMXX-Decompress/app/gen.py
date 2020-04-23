import zlib

fOld = open("./sklep_sms.amxx", "rb")
dataHeader = fOld.read(24)
#data32 = fOld.read(18642)
#data32 = zlib.decompress(data32)

fNew = open("./sklep_sms_x.amxx", "wb")
fCode32 = open("./32.txt", "rb")
fNew.write(dataHeader)
data32 = fCode32.read()
data32 = zlib.compress(data32)
print(len(data32))
fNew.write(data32)
fNew.close()