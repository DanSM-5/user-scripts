// @ts-check

// Ref: https://gist.github.com/zmwangx/eef99a2c6a57dbac38a6a8b8ca3a7870


/**
 * @param {string} b64 String in base64 encoding
 */
const base64ToUInt8Array = b64 =>
  Uint8Array.from(window.atob(b64), c => c.charCodeAt(0));
/**
 * @param {string} s
 */
const textToUInt8Array = s => new TextEncoder().encode(s);
/**
 * @param {Uint8Array} u8
 * @retuns {string}
 */
const UInt8ArrayToString = u8 => String.fromCharCode.apply(null, u8);
/**
 * @param {Uint8Array} u8
 */
const UInt8ArrayToBase64 = u8 => window.btoa(UInt8ArrayToString(u8));

(async () => {
  const key = await window.crypto.subtle.importKey(
    'raw',
    base64ToUInt8Array('HT24EFLxzRYATTG4PwMstxuIc6cnfnr4VjIeSJc9SMQ='),
    {
      name: 'AES-CTR'
    },
    false,
    ['encrypt', 'decrypt']
  );

  const encrypt = async data => {
    const iv = window.crypto.getRandomValues(new Uint8Array(16));
    const ciphertext = new Uint8Array(
      await window.crypto.subtle.encrypt(
        {
          name: 'AES-CTR',
          counter: iv,
          length: 128
        },
        key,
        textToUInt8Array(JSON.stringify(data))
      )
    );
    return {
      n: UInt8ArrayToBase64(iv),
      c: UInt8ArrayToBase64(ciphertext)
    };
  };

  const decrypt = async data => {
    const plaintext = UInt8ArrayToString(
      new Uint8Array(
        await window.crypto.subtle.decrypt(
          {
            name: 'AES-CTR',
            counter: base64ToUInt8Array(data.n),
            length: 128
          },
          key,
          base64ToUInt8Array(data.c)
        )
      )
    );
    return JSON.parse(plaintext);
  };

  console.log(
    JSON.stringify(await encrypt({ 'hello, world': '??,??' }))
  );
  console.log(
    await decrypt({
      n: 'I4ERqN5NHthiGzzIybMIug==',
      c:
      'sXm4vJ805FJYksYj7J3OOstpwdf/gl9o7mmJ3uTAUVfK99dE4oSmuaLsLlR8P18nKh4='
    })
  );
})();

/// WEB

// On web there it is not possible to decrypt data that does not match the padding
// "1234567890987654","2zYEsvUph3jYz+wLdo8J1jhXc/c32X5pWQWTXc1lt4M="
// Ref: https://stackoverflow.com/questions/54746103/what-padding-does-window-crypto-subtle-encrypt-use-for-aes-cbc
// Ref: https://stackoverflow.com/questions/75747038/javascript-subtle-crypto-no-padding-for-aes-ctr

// Sample
// window.crypto.subtle.generateKey(
//   {
//       name: "AES-CBC",
//       length: 128
//   },
//   true,
//   ["encrypt", "decrypt"]
// ).then(key => {
//   return window.crypto.subtle.decrypt(
//     {
//       name: "AES-CBC",
//       iv: (new TextEncoder).encode(iv)
//     },
//     key,
//     (new TextEncoder).encode("2zYEsvUph3jYz+wLdo8J1jhXc/c32X5pWQWTXc1lt4M=")
//   )
// }).then(o => {
//       debugger;
//       console.log((new TextDecoder).decode(o));
//   })

