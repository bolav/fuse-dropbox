fuse-dropbox [![Build Status](https://travis-ci.org/bolav/fuse-dropbox.svg?branch=master)](https://travis-ci.org/bolav/fuse-dropbox) ![Fuse Version](http://fuse-version.herokuapp.com/?repo=https://github.com/bolav/fuse-dropbox)
============

Use the Dropbox SDK from Fuse.


## Installation

Using [fusepm](https://github.com/bolav/fusepm)

    $ fusepm install https://github.com/bolav/fuse-dropbox

## Usage:

### UX

`<Dropbox ux:Global="Dropbox" />`

### JS

```
    var j = require('local.js');
    var db = require('Dropbox');
    db.link(j.app_key, j.app_secret).then(function (s) {
        console.log("We are linked " + s);
    });
```

### local.js:

```
module.exports.app_key = "<app-key>";
module.exports.app_secret = "<app-secret>";
```

### In the `unoproj`:

```
  "Dropbox": {
    "AppKey": "<app-key>"
  }
```
