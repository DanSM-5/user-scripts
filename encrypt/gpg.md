GPG
=======

# Using gpg

## Create key pairs

```bash
gpg --full-generate-key
```

## List keys

Public keys

```bash
gpg --list-public-keys
# OR
gpg --list-public-keys --keyid-format=long
```

Private keys

```bash
gpg --list-secret-keys
# OR
gpg --list-secret-keys --keyid-format=long
```

## Export key for sharing

```bash
# Sample from --list-public-keys
# pub   ed25519/C898ABD779D73967 2025-01-22 [SC] <-- Text after <algorithm>/
#       516E5411A4E64E1BB38E673CC898ABD779D73967 <-- Or this long one
# uid                 [ultimate] dan (Test gpg key) <dan@sample.com>
# sub   cv25519/96761A61CFF52923 2025-01-22 [E]
gpg --armor -o public.key --export [id from list]
```

## Import keys

```bash
# Public keys
gpg --import <shared key file>

# Private keys
gpg --allow-secret-key-import --import <shared key file>
```

## Encrypt a file

```bash
gpg --encrypt --recipient <email from received public key> <file>
# Example
gpg --encrypt --recipient edsm@sm.com README.md
# Generates README.md.gpg
```

## Decrypt file

```bash
gpg --decrypt -o <ouput file> <encrypted file>
# Example
gpg --decrypt -o README.md README.md.gpg
# Decrypts the README.md.gpg
```

## Searching for keys

```bash
gpg --search-keys names
```

Tries to search public gpg servers using the names

## Sign documents

To sign a document with GPG, you can use the following command to create a clear-text signature:

```bash
gpg --armor --output file.txt.asc --clear-sign file.txt
```

- The `--armor` option ensures that the output is in ASCII format

Alternatively, you can create a detached signature, which separates the signature from the original document:

```bash
gpg --armor --output file.txt.sig --detach-sign file.txt
```

This command generates a signature file file.txt.sig that can be used to verify the authenticity and integrity of file.txt.


## Verify signature

For clear-text signature:

```bash
gpg --verify file.txt.asc
```

For a detached signature:

```bash
gpg --verify file.txt.sig file.txt
```

