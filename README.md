# ROGUE STAR
[Website](https://rogue-star.net/) - [Forums](https://rogue-star.net/forums/index.php?sid=a270f1a1a2bdae63f0affd75af2fc4d6) - [Wiki](https://wiki.vore-station.net/)

Going to make a Pull Request? Make sure you read the [CONTRIBUTING.md](.github/CONTRIBUTING.md) first!

Rogue Star is a fork of VOREStation, which is a fork of Polaris, which itself is a fork of the Baystation12 code branch, for the game Space Station 13.

---

### LICENSE
The code for Rogue Star is licensed under the [GNU Affero General Public License](http://www.gnu.org/licenses/agpl.html) version 3, which can be found in full in LICENSE-AGPL3.txt.

Code with a git authorship date prior to `1420675200 +0000` (2015/01/08 00:00) are licensed under the GNU General Public License version 3, which can be found in full in LICENSE-GPL3.txt.

All code whose authorship dates are not prior to `1420675200 +0000` is assumed to be licensed under AGPL v3, if you wish to license under GPL v3 please make this clear in the commit message and any added files.

If you wish to develop and host this codebase in a closed source manner you may use all code prior to `1420675200 +0000`, which is licensed under GPL v3.  The major change here is that if you host a server using any code licensed under AGPLv3 you are required to provide full source code for your servers users as well including addons and modifications you have made.

See [here](https://www.gnu.org/licenses/why-affero-gpl.html) for more information.

All assets including but not limited to icons and sounds files located in the following locations are only to be used with permission of their creator, VerySoft, and may not be used for any purpose without permission.
`rogue-star/icons/rogue-star`
`rogue-star/sound/rogue-star`

Any files located in the
`rogue-star/goon`,
`rogue-star/icons/goonstation`, or
`rogue-star/sound/goonstation`
directories, or any subdirectories of mentioned directories are licensed under the
Creative Commons 3.0 BY-NC-SA license
(https://creativecommons.org/licenses/by-nc-sa/3.0)

All assets including icons and sound are under a [CC BY-SA 3.0](http://creativecommons.org/licenses/by-sa/3.0/) license unless otherwise indicated.

Attributions and other licenses with links to original works are noted in [ATTRIBUTIONS.md](./ATTRIBUTIONS.md).

Additional Attribution Terms for Rogue Star UI (AGPL § 7 (b)-(c))

Preservation of visible credit

Any part of the Program that, in the un-modified version, displays the text “Rogue Star UI” or “RS-UI” must continue to display a substantially similar credit.  If you redesign that element, place the same credit in an About dialog or settings screen reachable in no more than two user actions.

Preservation of source-file headers

Every source file that carries a copyright or attribution header referencing “Rogue Star UI”, “RS-UI”, or the original authors must retain that header (you may update years, add your own notice below it, or re-format comments, but the original attribution text and copyright holder(s) must remain legible).

Modified versions
If you convey a modified version, add “(modified)” after the credit or otherwise mark the interface so users know it is not the original. 

### GETTING THE CODE
The simplest way to obtain the code is using the github .zip feature. If you do this, you won't be able to make a Pull Request later, though. You'll need to use the git method.

Click [here](https://github.com/TS-Rogue-Star/Rogue-Star/archive/master.zip) to get the latest code as a .zip file, then unzip it to wherever you want.

The more complicated and easier to update method is using git.  You'll need to download git or some client from [here](http://git-scm.com/).  When that's installed, right click in any folder and click on "Git Bash".  When that opens, type in:

    git clone https://github.com/TS-Rogue-Star/Rogue-Star.git

(hint: hold down ctrl and press insert to paste into git bash)

This will take a while to download, but it provides an easier method for updating.

### INSTALLATION

First-time installation should be fairly straightforward.  First, you'll need BYOND installed.  You can get it from [here](http://www.byond.com/).

This is a sourcecode-only release, so the next step is to compile the server files.  Open vorestation.dme by double-clicking it, open the Build menu, and click compile.  This'll take a little while, and if everything's done right you'll get a message like this:

    saving vorestation.dmb (DEBUG mode)

    vorestation.dmb - 0 errors, 0 warnings

If you see any errors or warnings, something has gone wrong - possibly a corrupt download or the files extracted wrong, or a code issue on the main repo.  Ask on IRC.

Once that's done, open up the config folder.  You'll want to edit config.txt to set the probabilities for different gamemodes in Secret and to set your server location so that all your players don't get disconnected at the end of each round.  It's recommended you don't turn on the gamemodes with probability 0, as they have various issues and aren't currently being tested, so they may have unknown and bizarre bugs.

You'll also want to edit admins.txt to remove the default admins and add your own.  "Host" is the highest level of access, and the other recommended admin levels for now are "Game Admin" and "Moderator".  The format is:

    byondkey - Rank

where the BYOND key must be in lowercase and the admin rank must be properly capitalised.  There are a bunch more admin ranks, but these two should be enough for most servers, assuming you have trustworthy admins.

Finally, to start the server, run Dream Daemon and enter the path to your compiled vorestation.dmb file.  Make sure to set the port to the one you  specified in the config.txt, and set the Security box to 'Trusted'.  Then press GO and the server should start up and be ready to join.

---

### UPDATING

To update an existing installation, first back up your /config and /data folders
as these store your server configuration, player preferences and banlist.

If you used the zip method, you'll need to download the zip file again and unzip it somewhere else, and then copy the /config and /data folders over.

If you used the git method, you simply need to type this in to git bash:

    git pull

When this completes, copy over your /data and /config folders again, just in case.

When you have done this, you'll need to recompile the code, but then it should work fine.

---

### Configuration

For a basic setup, simply copy every file from config/example to config.

---

### SQL Setup

The SQL backend for the library and stats tracking requires a MySQL server.  Your server details go in /config/dbconfig.txt, and the SQL schema is in /SQL/tgstation_schema.sql.  More detailed setup instructions arecoming soon, for now ask in our Discord.
