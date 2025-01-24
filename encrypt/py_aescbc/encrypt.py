import base64
from Crypto.Cipher import AES
from args import getArgsAsDictionary, getSafe
from common import getBites, getEncoded

defaultKey = b'1234567890987654'
args = getArgsAsDictionary()
padblock = '\x00'

key = getSafe("key", args)
key = getBites(key) if key is not None else defaultKey
IV = getBites(getSafe("iv", args))
data = getSafe("data", args)
if IV == None: IV = key

if key == None: raise "Wrong key format"
if data == None: raise "No data to decrypt"

data += padblock * (16 - len(data) % 16)
data = getEncoded(data)

cipher = AES.new(key, AES.MODE_CBC, IV)
encrypted = base64.b64encode(cipher.encrypt(data)).decode("utf-8")

print(encrypted)

