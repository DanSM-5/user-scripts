Python aes
==========

Sample script that implements `Crypto.Cipher` package from python to do aes-cbc encryption.

This had the simple usecase of decrypt the hidden urls for certain "j" downlaoder.

## Usage

```bash
python3 encrypt.py data=https://sample.url.com/test/123 # iv=16bitsofsometing key=shhhhhhhh
# "2zYEsvUph3jYz+wLdo8J1jhXc/c32X5pWQWTXc1lt4M="

python3 decrypt.py data=2zYEsvUph3jYz+wLdo8J1jhXc/c32X5pWQWTXc1lt4M=
# "https://sample.url.com/test/123"
```

