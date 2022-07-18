# TitanfallPropEditor BETA (FORKED)

For any bugs please DM x3Karma#6984 on discord, or create an issue in this repo.

I cannot guarantee that I will know how to fix this mod.

This is a fork of Pebbers.MapEditor which is a fork of R5Reloaded's map editor with alot of modifications. (lol)

Sort of maintained by x3Karma, but any modifications I made here are to suit my own needs. I probably won't take requests.

[Tutorial](https://www.youtube.com/watch?v=lu1X-1ufKbc)

# Changes Made in This Fork
## Place Mode
- Changed keybinds for moving prop up and down to numpad 9 and 7, respectively.
- Fix client not updating prop angles when using `angles x y z`
- Numpad 1 now changes the x angle of the prop by 45 degrees each press, while numpad 3 changes the z angle.
- Holding down a key will now continuously move the prop.

# FAQ:
## How to download the map editor?
Go to the releases tab then download the latest version and put it in your mods folder. <br/>
Alternatively, download the entire zip in the main branch which will likely be more updated than the release tab.
<br/><br/>
If you want to download the original mod (which is not updated since v1.0.3), you can head [here](https://github.com/Vysteria/TitanfallMapEditor).

## How to download a map?
Get the map file and replace it in your save files folder (mod/scripts/vscripts/maps) <br/>
Load it via a script or the ingame menu.

## I cant find the asset I want!
Every map has a different set of assets, we are working on improving it so you can use any props but look in different maps for now. <br/>
Also not everything is a prop, it can be something in the map .bsp by itself.

## Saving doesnt work!
Make sure the name of the mod in the mods folder is `Pebbers.MapEditor`.

## How to use the map editor?
1. Enable sv_cheats in console by doing `sv_cheats 1`
2. Give your self the editor by doing `give mp_weapon_editor`
3. Start editing!

To change the model or the mode go to your controls settings and modify the keys
1. The place mode is used to place new props (Use the num pad for precise positioning)
2. The extend mode is to repeat a prop in a certain direction (Use the scroll wheel to increase duplication count, this is the fastest way for building many props rn)
3. The delete mode deletes existing props
4. The bulk place mode is currently broken pls dont use it

## Exporting
Open the model menu while in Place Mode, select which save file you want then press save.

## Loading
Loading maps to continue building on them is done via the model menu, select the map of choice then press on the Load button. <br/>
If you are a modder all you need to do to load a map at any given time is to run LoadPropMap(mapIndex), this can be done whenever and it will delete all already spawned props.
