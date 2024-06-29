Scoop Info
==========

# Update apps.json

1. Start a node interactive session
2. Create temp.json from command `scoop export > temp.json`
3. Run the following script that will print the new entries in json format
```javascript
const apps = require('./apps.json');
const temp = require('./temp.json');
// const fs = require('fs');

const keys = Object.keys(apps);

keys.forEach(key => {
    const missing = temp[key].filter(entry => !apps[key].find(existing => existing.Name === entry.Name));
    const jsonString = JSON.stringify(missing, null, 4)
    console.log(jsonString);
    // apps[key].push(...missing);
    // apps[key].sort((a, b) => {
    //     var textA = a.Name.toUpperCase();
    //     var textB = b.Name.toUpperCase();
    //     return (textA < textB) ? -1 : (textA > textB) ? 1 : 0;
    // });
});

// fs.writeFileSync('apps.json', JSON.stringify(apps, null, 4), { encoding: 'utf8', flag: 'w' });
```

