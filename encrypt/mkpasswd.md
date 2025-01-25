Usage mkpasswd
========

# Hash passwords

```bash
mkpasswd -m sha512crypt --salt "abcdefgh" --stdin <<< "plainpassword" > hashedpassword.txt
```

