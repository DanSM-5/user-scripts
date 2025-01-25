// @ts-check

const { pbkdf2, pbkdf2Sync, randomBytes } = require('crypto');

/**
 * @param {number} [bytes] Number of bytes to use
 */
const getSalt = (bytes = 16) => {
  return randomBytes(bytes).toString('hex');
};

/**
 * @param {string} password Secret to hash
 * @param {number} [iterations] Number of iterations
 * @example ```
 * const hashed = hashSync('shhhhhhhh').toString('hex');
 * ```
 */
const hashSync = (password, iterations = 1000) => {
  const salt = getSalt();
  return pbkdf2Sync(password, salt, iterations, 64, 'sha512');
};

/**
 * @param {string} password Secret to hash
 * @param {number} [iterations] Number of iterations
 * @returns {Promise<Buffer | undefined>} Result of hash
 * @example ```
 * hash('shhhhhhhh').then((buffer) => {
 *   const hashed = buffer.toString('hex');
 * });
 * ```
 */
const hash = (password, iterations = 1000) => {
  const deferred = /**
    @type {{
      promise: Promise<Buffer | undefined>;
      resolve: (resolveArg: Buffer | undefined) => void;
      reject: typeof Promise.reject
    }}
  */ (Promise.withResolvers());

  const salt = getSalt();
  pbkdf2(password, salt, iterations, 64, 'sha512', (err, derived) => {
    if (err) {
      deferred.reject(err);
      return;
    }

    deferred.resolve(derived);
  });

  return deferred.promise;
}

module.exports = {
  getSalt,
  hash,
  hashSync,
};

