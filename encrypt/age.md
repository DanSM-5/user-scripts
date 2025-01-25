AGE file encryption
=========

## Create key

```bash
# Private key is stored in key.txt
age-keygen -o key.txt
```

## Encrypt

### Stdin/out

```bash
<content> | age -r <public key from key.txt> > <outfile>
# Example
tar cvz ~/data | age -r age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p > data.tar.gz.age
```

### Files

```bash
age -r <public key from key.txt> -o <out file> <file>
# Example
age -r age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p \
    -r age1lggyhqrw2nlhcxprm67z43rta597azn8gknawjehu9d9dl0jq3yqqvfafg \
    -o example.jpg.age example.jpg
```

## Decrypt

```bash
age --decrypt -i <key file> <encrypted file> > <out file>
# Example
age --decrypt -i key.txt README.md.age > .\README.md
```

## Using SSH keys

```bash
age -R ~/.ssh/id_ed25519.pub example.jpg > example.jpg.age
age -d -i ~/.ssh/id_ed25519 example.jpg.age > example.jpg
```

### Encrypt to public keys in github

Encrypting to the public keys in a github profile

```bash
curl https://github.com/user.keys | age -R - example.jpg > example.jpg.age
```

