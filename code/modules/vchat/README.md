# VChat

## Development

Here, js/vchat.js is the client-side javascript that handles the chat.
Elsewhere, vchat_client.dm handles the server-side DM code for the chat.
Also, js/polyfills.js are polyfills for the old Trident web engine for Byond <= 515.

### vchat.js

vchat.js is a development file - it is not actually included in the actual game code. Instead, what the game expects is the minified version "vchat.min.js".

Therefore, to have your changes in "vchat.js" apply to the game for either PR or testing - you must first minify your script. You can use the npm project in this folder if you understand what that is, and `npm install` then `npm run uglify` to minify the files. (There's also `npm run eslint`)

If you are unfamiliar with NPM or don't want to set that up, simply you copy the file contants in vchat.js, paste them into https://codebeautify.org/minify-js or any similar tool and paste its output into vchat.min.js.

### ss13styles.css
Elsewhere, this file handles chat colours, background colours, filtering.

Please keep this file synchronized with code\stylesheet.dm where possible (filters, lightmode colours).
