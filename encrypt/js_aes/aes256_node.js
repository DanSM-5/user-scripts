// @ts-check

// ref: https://gist.github.com/siwalikm/8311cf0a287b98ef67c73c1b03b47154

const fs = require('fs');
const crypto = require('crypto');
// import fs from 'fs';
// import crypto from 'crypto';

// Number of random bypes
const DEFAULT_LENGTH = 32;
const ALGORITHM = 'aes-256-cbc';

/**
 * @param {string} key Key used as seed to generate random bytes
 * @param {number} length Length of the random bytes to generate
 * @returns {Buffer} Buffer with {length} number of bytes based on key
 */
const getKey = (key, length = DEFAULT_LENGTH) => {
  return Buffer.concat([Buffer.from(key), Buffer.alloc(length)], length);
}

/**
 * @param {object} options Options to encryption
 * @param {crypto.BinaryLike} options.content Content to be encrypted
 * @param {string} options.password Password for encryption
 * @param {number} [options.key_length] Length for the encryption key
 * @returns {string} encrypted content as string
 */ 
const encrypt = ({ content, password, key_length = DEFAULT_LENGTH }) => {
  // NOTE: Initialization vector must be same size as block size
  // In aes256 it may use a 256 key but still uses 128-bit blocks.
  // Ref: https://security.stackexchange.com/questions/90848/encrypting-using-aes-256-can-i-use-256-bits-iv
  const iv = crypto.randomBytes(16);
  const key = getKey(password, key_length);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  let encrypted = typeof content === 'string'
    ? cipher.update(content, 'utf8')
    : cipher.update(content);
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  return `${iv.toString('hex')}:${encrypted.toString('hex')}`;
}

/**
 * @param {Object} options Options for decrypting
 * @param {string} options.enc_content Encrypted content
 * @param {string} options.password Password for decryption
 * @param {number} [options.key_length] Length of the decryption key
 * @param {'string'|'buffer'} [options.type] Type of the expected return type. It is string by default.
 * @return {string | Buffer}
 */
const decrypt = (options) => {
  const { enc_content, password, key_length = DEFAULT_LENGTH } = options;
  const key = getKey(password, key_length);
  const [iv, ...content] = enc_content.split(':');
  const decipher = crypto.createDecipheriv(
    ALGORITHM,
    Buffer.from(key),
    Buffer.from(iv, 'hex'),
  );
  let decrypted = decipher.update(Buffer.from(content.join(':'), 'hex'));
  decrypted = Buffer.concat([decrypted, decipher.final()]);

  if (options.type == null || options.type === 'string') {
    console.log(options.type)
    return decrypted.toString('utf8');
  }

  console.log(options.type)
  return decrypted;
}

/**
 * Encrypts a file in a given path with a given password
 * @param {string} path Path to file to encrypt
 * @param {string} password Password to encrypt file
 * @return {string|undefined} Encrypted data
 */
const encryptFile = (path, password) => {
  try {
    const data = fs.readFileSync(path, 'utf8');
    /** @type {string} */
    const encryptedData = encrypt({ content: data, password });
    return encryptedData;
  } catch (err) {
    console.error(err);
    return undefined;
  }
}

/**
 * Attempt to decrypt a file at given path with a given password
 * @param {string} path Path to encrypted file
 * @param {string} password Password to decrypt file
 * @return {string|undefined} Decrypted data
 */
const decryptFile = (path, password) => {
  try {
    const encryptedData = fs.readFileSync(path, 'utf8');
    /** @type {string} */
    const decryptedData = (/** @type {any} */ (decrypt({ enc_content:  encryptedData, password, type: 'string' })));
    return decryptedData;
  } catch (err) {
    console.error(err);
    return undefined;
  }
}

/**
 * Creates a encrypted file at {path} and {password}
 * Resulting file will be placed on same location as the source
 * with the extension provided.
 * @param {string} path Path to file to encrypt
 * @param {string} password Password to encrypt file
 */
const createEnc = (path, password, ext = 'enc') => {
  const encrypted = encryptFile(path, password);
  if (encrypted) {
    fs.writeFileSync(`${path}.${ext}`, encrypted);
  }
}

/**
 * Attempts to decrypt a file in a given path with a given password
 * Resulting file will have the same name without the encrypted extension
 * @param {string} path Path to file to encrypt
 * @param {string} password Password to encrypt file
 */
const createFromEnc = (path, password) => {
  const extIndex = path.lastIndexOf('.');
  const decryptedLocation = path.substring(0, extIndex);
  
  const data = decryptFile(path, password);
  if (data) {
    fs.writeFileSync(decryptedLocation, data);
  }
}

module.exports = {
  getKey,
  encrypt,
  decrypt,
  encryptFile,
  decryptFile,
  createEnc,
  createFromEnc,
};

