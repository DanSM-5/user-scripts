const crypto = require('crypto');

const defaultKey = "1234567890987654";

const args = process.argv
  .slice(2)
  .map(arg => {
    const key = arg.substring(0, arg.indexOf("="));
    const value = arg.substring(arg.indexOf("=") + 1);
    return { [key]: value };
  })
  .reduce((acc, curr) => ({ ...acc, ...curr }), {});

/**
 * If needed, key can be converted back to hex string with 
 * key.split("").map(i => i.charCodeAt().toString(16)).join("");
 */
const convertFromHexString = value =>
  value.split("")
    .reduce((acc, curr, i) => i % 2 === 0 ? (acc.push(curr), acc) : (acc[acc.length - 1] += curr, acc), [])
    .map(ch => String.fromCharCode(parseInt(ch, 16))).join("");

const bind = (func, value) => {
  const result = value ? func(value) : value;
  return next => next ? bind(next, result) : result;
};

const getValue = (val = "") => {
  switch (val.length) {
    case 16:
      return val;
    case 32:
      return convertFromHexString(val);
    default:
      console.warn("key or iv must be 16 or 32 bits");
      return null;
  }
};

const getEncoded = value => (new TextEncoder()).encode(value);
const getBites = value => bind(getValue, value)(getEncoded)();

const key = getBites(args?.key ?? defaultKey);
const IV = getBites(args?.iv) ?? key;
const data = args?.data ?? null;

if (!data) {
  throw "No data to decrypt";
}

if (!key || !IV) {
  throw "Wrong key format";
}

const decypher = crypto.createDecipheriv('aes-128-cbc', key, IV);
decypher.setAutoPadding(false); // without this the decryption will fail with the last segment
const decrypted = decypher.update(data, 'base64', 'utf8');
console.log(`${decrypted}${decypher.final('utf8')}`);

