# crutches
Crutches is a small (218 lines of code) standalone script that allows people to use a crutch in their right arm. The crutch automatically gets hidden in vehicles and when you take out weapons. If you fall or punch someone you’ll drop your crutch, but don’t be afraid, you can always just pick it up again.

The script was just made for fun, so the code could probably have been written somewhat better, however it is more than good enough for its purpose. The script runs at 0.0 ms when not using a crutch and anywhere from 0.0 to 0.4 ms when using it (usually 0.1 ms unless you drop the crutch).

**Usage**<br />
To get out or take away your crutch you simply use the /crutch command.

**Developer Info**<br />
I’m releasing the script as a standalone to allow more people to utilize it, if you wish to add the crutch as an item you’ll have to do it yourself.

You can also set the “ped movement clipset” aka. the walking style the player will revert to when no longer using the crutch, this is simply done by calling the export SetWalkStyle(walk).

Example:<br />
`exports.crutches:SetWalkStyle("move_m@gangster@var_e")`

for more info see the forum post: https://forum.cfx.re/t/standalone-crutches/4843073
