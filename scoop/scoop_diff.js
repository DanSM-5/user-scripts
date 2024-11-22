// @ts-check

/** @typedef {{
 *   Name: string;
 *   Source: string;
 *   Updated: string;
 *   Manifests: number;
 * }} Bucket */
/** @typedef {{
 *   Name: string;
 *   Info: string;
 *   Version: string;
 *   Updated: string;
 *   Source: string;
 * }} App */
/** @typedef {{ apps: App[]; buckets: Bucket[] }} manifest */

/** @type manifest */
const apps = require('./apps.json');
/** @type manifest */
const temp = require('./temp.json');
// const fs = require('fs');

/**
 * @type {['buckets', 'apps']}
 */
// @ts-expect-error Casting keys from apps object
const keys = Object.keys(apps);
/** @type manifest */
const missingManifest = { apps: [], buckets: [], };

keys.forEach(key => {
  const missing = temp[key].filter(entry => !apps[key].find(existing => existing.Name === entry.Name));
  // @ts-expect-error Assignment is safe
  missingManifest[key] = missing;
});

// Output manifest
const jsonString = JSON.stringify(missingManifest, null, 4)
// Remove log if printed updated
console.log(jsonString);

// /** @type manifest */
// const updatedManifest = { apps: [], buckets: [] };
// keys.forEach(key => {
//   const existingApps = apps[key];
//   const tempApps = temp[key];
//   for (let i = 0; i < existingApps.length; i++) {
//     const app = existingApps[i];
//     const tmp = tempApps[i];
//     if (tmp != null) {
//       if ('Version' in app && 'Version' in tmp) {
//         app.Version = tmp.Version;
//         app.Info = tmp.Info;
//         app.Source = tmp.Source;
//         app.Updated = tmp.Updated;
//       } else if ('Manifests' in app && 'Manifests' in tmp) {
//         app.Source = tmp.Source;
//         app.Updated = tmp.Updated;
//         app.Manifests = tmp.Manifests;
//       }
//     }
//
//     // Add updated app
//     // @ts-expect-error Adding app to specific array
//     updatedManifest[key].push(app);
//   }
//
//   // Pleasing type check without an ignore :)
//   if (key === 'buckets') {
//     updatedManifest[key].push(...missingManifest[key]);
//   } else {
//     updatedManifest[key].push(...missingManifest[key]);
//   }
//
//   // Sort keys by name
//   updatedManifest[key].sort((/** @type {{ Name: string; }} */ a, /** @type {{ Name: string; }} */ b) => {
//     var textA = a.Name.toUpperCase();
//     var textB = b.Name.toUpperCase();
//     return (textA < textB) ? -1 : (textA > textB) ? 1 : 0;
//   });
// })
//
// // Print updated manifest
// console.log(JSON.stringify(updatedManifest, null, 4));
// // Update file
// const fs = require('fs');
// fs.writeFileSync('apps.json', JSON.stringify(updatedManifest, null, 4), { encoding: 'utf8', flag: 'w' });

