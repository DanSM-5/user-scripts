// @ts-check

// Sample script to use jsonwebtoken with aes255
// To generate certs see create_keys.sh

const jwt = require('jsonwebtoken');
const { PRIVATE_KEY } = process.env;

/**
 * @param {string | object | Buffer} payload Object to sign
 * @param {string} private_key Private key for signing a token
 * @returns {Promise<string | undefined>}
 */
const createToken = (payload, private_key) => {
  const deferred = /**
      @type {{
        promise: Promise<string | undefined>;
        resolve: (resolveArg: string | undefined) => void;
        reject: typeof Promise.reject
      }}
    */ (Promise.withResolvers());
  jwt.sign(payload, private_key, { algorithm: 'RS256' }, (err, token) => {
    if (err) {
      deferred.reject(err);
      return;
    }

    deferred.resolve(token);
  })

  return deferred.promise;
};

/**
 * @param {string | object | Buffer} payload Object to sign
 * @param {string} private_key Private key for signing a token
 * @returns {string | undefined}
 */
const createTokenSync = (payload, private_key) => {
  let token;
  try {
    token = jwt.sign(payload, private_key, { algorithm: 'RS256' });
  } catch (error) {
    console.error(error);
  }
  return token;
};

/** @typedef {Parameters<NonNullable<Parameters<typeof jwt.verify>[3]>>[1]} VerifyPayload */

/**
 * @param {string} token Token to verify
 * @param {string} key Private or public key
 * @return {Promise<VerifyPayload>} Verified payload
 */
const verify = (token, key) => {
  const deferred = /**
      @type {{
        promise: Promise<VerifyPayload>;
        resolve: (resolveArg: VerifyPayload) => void;
        reject: typeof Promise.reject
      }}
    */ (Promise.withResolvers());
  jwt.verify(token, key, (err, payload) => {
    if (err) {
      deferred.reject(err);
      return;
    }

    deferred.resolve(payload);
  });

  return deferred.promise;
};

/**
 * @param {string} token Token to verify
 * @param {string} key Private or public key
 */
const verifySync = (token, key) => {
  try {
    return jwt.verify(token, key);
  } catch (error) {
    console.error(error);
  }
};

module.exports = {
  createToken,
  createTokenSync,
  verify,
  verifySync,
  extract: jwt.decode,
}

