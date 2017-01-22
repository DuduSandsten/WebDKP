-----------------------------------------------
WEB DKP ADDON
-----------------------------------------------
Originally Created by ZeddZorandor of Stromscale

Description:
The webdkp addon is used together with the site
www.webdkp.com to help guild leaders manage thier
dkp. 

Information recorded by the addon is stored into a log file
which can then be uploaded by the guild master to the
website using the SyncTool. 

~~~~~~~~~~~~~~~~~~~~~~
HOW TO USE:
~~~~~~~~~~~~~~~~~~~~~~

type \webdkp

For help with the addon, check out the tutorial at:
http://www.webdkp.com/index.php?view=tutorial


Type into chat:
!startbid [Item Link]

To start dkp bidding

~~~~~~~~~~~~~~~~~~~~~~
SANDSTEN CHANGELOG
~~~~~~~~~~~~~~~~~~~~~~
2017-01-23
  Added feature to give out a specified flat decay to every player.

2016-12-19
  Fixed DKP not giving awarded automatically in AQ40
  Added the minimap icon command Fix negative DKP

2016-08-29
  Added ability to reward custom dkp so that the winner of a bid can be awarded anything entered.
  This way you can use a DKP system using Vickrey Auction system (a.k.a. "Second-price sealed bid auction")

  The bench feature implemented by Tzui appears to not work all the time.
  !bench dkp
  !bench dkp Player
  
  To add any player to the bench list type
  !bench add Player


~~~~~~~~~~~~~~~~~~~~~~
OLD FEATURES
~~~~~~~~~~~~~~~~~~~~~~
- Complete overhaul of the addon from version 1. 
- GUI interface changed to show a live view of DKP in game
- Filters can be applied to the table to only show certain classes
- Seperate tabs are provided for awarding points and awarding items
- A new SYNC tool that uploads syncs your dkp addon with the website
  Requires .Net 2.0 Framework:
  http://www.microsoft.com/downloads/details.aspx?FamilyID=0856EACB-4362-4B0D-8EDD-AAB15C5E04F5&displaylang=en

- Whisper DKP!
  Other members can now whisper you to have you automattically whisper them back with information
  (Whispers are hidden from you, so you dont' get bogged down in info)

  Commands that you can be whispered:
  !help - sends them a list of commands
  !dkp  - sends the person who whispered you their current dkp
  !list - Lists the dkp of everyone in your current group
  !listall - Lists the dkp of everyone in your dkp table

  The two list commands can have class names append to them to limit them to certain classes. 
  For example:
  !list hunter           - Shows the dkp of all the hunters in the current group
  !listall hunter rogue  - Shows the dkp of all the hunters and rogues in the guild

