# PersistenceXP
Persistence for XP11 Aircraft

Switch positions will be recorded when the Park Brake is set and the Left Engine is off.
It will automatically reload the last saved switch positions 10 seconds after the sim loads.

*In progress* Modifying to work with aircraft using default XP data and select third party aircraft using custom datarefs.

Third Party Aircraft List
Carenado C550 Citation II


Limitations
===========
Third party aircraft require coding of any custom commands to have full save and reload functionality.


Carenado C550 Citation II
I have not found a way to shut down the engines in a manner that will allow them to be restarted. If the scenario is loaded with engines running, the script will pull the power lever latches, however you will have to manually move the power levers to cutoff.

Prerequisite
============
This plugin uses the FlyWithLUA plugin to interface with X-Plane.
It is available freely from the .org 

https://forums.x-plane.org/index.php?/files/file/38445-flywithlua-ng-next-generation-edition-for-x-plane-11-win-lin-mac/


Luna INI Parser (LIP) is included as an additional plugin module for use with FlyWithLua. This module allows for the saving and reading of settings data within LUA. It has been included in this package under the MIT Licence offered by creater Carreras Nicholas.
https://github.com/Dynodzzo/Lua_INI_Parser


Installation
============

Copy the Scripts and Modules folders into the main folder of FlyWithLUA: 
X-Plane 11 > Resources > plugins > FlyWithLua
NOTE: LIP is a common module and may prompt to overwrite if it already exists in your instalation.

Saving and loading switch positions can be manually accomplished by selecting the option in:
Plugins > FlyWithLua > FlyWithLua Macros > PersistenceXP Save / Load


Disclaimer / Feedback
=====================

This package is to be distributed as Freeware only.
Installation and use of this package is at your own risk. 

This is the first time I have coded a plugin, any feedback is welcome.
Bug reports, please include the x-plane log.txt file in the main x-plane folder for the flight in question. 

This plugin is still a work in progress, to be considered as public beta. Errors may exist.




Change Log
==========
* V0.1 - Initial Beta Release
* V1.0 - Initial Release
* V2.0 - Recoded to work with all deafult aircraft and Carenado C550
