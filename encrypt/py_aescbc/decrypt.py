import base64
from Crypto.Cipher import AES
from args import getSafe, getArgsAsDictionary
from common import getBites

defaultKey = b'1234567890987654'
args = getArgsAsDictionary()

key = getSafe("key", args)
key = getBites(key) if key is not None else defaultKey
IV = getBites(getSafe("iv", args))
data = getSafe("data", args)
if IV == None: IV = key

if key == None: raise "Wrong key format"
if data == None: raise "No data to decrypt"

enc_cypher = base64.b64decode(data)
decipher = AES.new(key, AES.MODE_CBC, IV)
plaintext = decipher.decrypt(enc_cypher).decode("utf-8")
print(f'{plaintext}')

# text = "https://sample.url.com/test/123"

# padding
# text += '\x00' * (16 - len(text) % 16)
# text = getEncoded(text)

# print("*** SEPARATOR ***")
# print(text)

# cipher = AES.new(key, AES.MODE_CBC, IV)
# encrypted = base64.b64encode(cipher.encrypt(text))

# print(encrypted)

