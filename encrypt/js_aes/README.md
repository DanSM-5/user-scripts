JS AES Encryption
============

Sample scripts to use aes encryption with on javascript in both the browser with the node [`crypto`](https://nodejs.org/api/crypto.html) package and the [`window.crypto.subtle`](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto) module in the browser.

## aes256_node.js

### Encrypt and decrypt files

Encrypt and decrypt a file using `aes-256-cbc` algorithm.

```javascript
const fs = require('fs');
const { createEnc, createFromEnc } = require('aes256_node.js');
const password = 'shhhhhhhh';
const file = '/path/to/path';
createEnc(file, password); // creates '/path/to/file.enc'

// Removing for testing purposes
fs.rmSync(file)

// Attempts to decrypt file
createFromEnc(`${file}.enc`, password); // will recreate '/path/to/file' if the password is right
```

