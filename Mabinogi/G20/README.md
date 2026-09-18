# Mabinogi G20 Private Server Guide

> A practical guide to deploying, configuring, translating, administering, modifying, and troubleshooting a Mabinogi Generation 20 (G20) private server environment.

---

## Table of Contents

* [1. Introduction](#1-introduction)

  * [What This Guide Covers](#what-this-guide-covers)
  * [What This Guide Assumes](#what-this-guide-assumes)
  * [Development vs. Production](#development-vs-production)
* [2. Server Architecture](#2-server-architecture)

  * [Component Overview](#component-overview)
  * [Startup Order](#startup-order)
  * [How a Login Works](#how-a-login-works)
* [3. Requirements](#3-requirements)

  * [Software](#software)
  * [Server Files](#server-files)
  * [Client Files](#client-files)
  * [Recommended Tools](#recommended-tools)
* [4. Recommended Directory Layout](#4-recommended-directory-layout)
* [5. Preparing Windows](#5-preparing-windows)

  * [SQL Server](#sql-server)
  * [Manual File Preparation](#manual-file-preparation)
  * [Symbolic Links](#symbolic-links)
* [6. Database Installation](#6-database-installation)

  * [SQL Server Configuration](#sql-server-configuration)
  * [Restoring Databases](#restoring-databases)
  * [Logical File Names](#logical-file-names)
  * [Database Connection Configuration](#database-connection-configuration)
* [7. Server Configuration](#7-server-configuration)

  * [XMLDB](#xmldb)
  * [Authenticator](#authenticator)
  * [DB_XMLServer](#db_xmlserver)
  * [Configuration File Reference](#configuration-file-reference)
* [8. Client Configuration](#8-client-configuration)

  * [Language Files](#language-files)
  * [UI Upload Service](#ui-upload-service)
  * [Client URLs](#client-urls)
* [9. Starting the Server](#9-starting-the-server)

  * [Startup Order](#startup-order-1)
  * [startall.bat](#startallbat)
  * [First Boot Checklist](#first-boot-checklist)
* [10. Accounts and GameMaster Setup](#10-accounts-and-gamemaster-setup)

  * [NPC Account](#npc-account)
  * [GameMaster Account](#gamemaster-account)
  * [Creating a Player](#creating-a-player)
* [11. NPCClient Initialization](#11-npcclient-initialization)
* [12. Translation and Language Packs](#12-translation-and-language-packs)

  * [Understanding Language Packs](#understanding-language-packs)
  * [Extraction](#extraction)
  * [Merging Localized Data](#merging-localized-data)
  * [Repacking](#repacking)
  * [Installing the Finished Pack](#installing-the-finished-pack)
* [13. Server Administration](#13-server-administration)

  * [Server Startup and Shutdown](#server-startup-and-shutdown)
  * [Server and Channel Names](#server-and-channel-names)
  * [Database Maintenance](#database-maintenance)
  * [Removing a Corrupt Item](#removing-a-corrupt-item)
  * [Database Backups](#database-backups)
* [14. Modifying Game Data](#14-modifying-game-data)

  * [XML Data](#xml-data)
  * [Scripts](#scripts)
  * [Skills](#skills)
  * [Events](#events)
  * [Client Binary Modifications](#client-binary-modifications)
* [15. Reverse Engineering and Development Tools](#15-reverse-engineering-and-development-tools)
* [16. Networking](#16-networking)
* [17. Troubleshooting](#17-troubleshooting)

  * [Troubleshooting Method](#troubleshooting-method)
  * [Server Does Not Start](#server-does-not-start)
  * [World Does Not Load](#world-does-not-load)
  * [NPCs Are Delayed](#npcs-are-delayed)
  * [Client Does Not Launch](#client-does-not-launch)
* [18. Known Bugs and Limitations](#18-known-bugs-and-limitations)
* [19. Version Compatibility](#19-version-compatibility)
* [20. Quick Reference](#20-quick-reference)
* [21. Appendix: Steam Client Extraction](#21-appendix-steam-client-extraction)
* [22. Appendix: Legacy SQL Server Installation](#22-appendix-legacy-sql-server-installation)
* [23. Changelog](#23-changelog)

---

# 1. Introduction

## What This Guide Covers

This guide documents a complete Mabinogi Generation 20 private-server environment, including:

* Server architecture
* SQL Server installation
* Database restoration
* Server configuration
* Client configuration
* Authentication
* Login and channel services
* NPCClient initialization
* Account creation
* GameMaster configuration
* Translation and localization
* `.pack` extraction and repacking
* Server administration
* Database maintenance
* Client modification
* Reverse-engineering tools
* Troubleshooting
* Known bugs and limitations

The goal is not simply to provide a list of commands.

Instead, this guide explains **what each component does, why it is required, how the components interact, and how to diagnose problems when something goes wrong.**

---

## What This Guide Assumes

The guide assumes that the reader is comfortable with basic Windows administration, file management, and editing configuration files.

Basic familiarity with the following is helpful:

* Windows services
* SQL Server
* XML
* INI files
* Command Prompt
* Batch files
* Archives such as `.7z`
* Basic networking

You do not need to understand the entire Mabinogi server architecture before starting. The architecture section explains the major components.

---

## Development vs. Production

This guide is primarily structured around a **development/testing environment**.

A development server can reasonably use:

* Localhost addresses
* GM accounts
* Test configurations
* Debug clients
* Development tools
* Disposable databases
* Verbose logging

An internet-facing production server should additionally consider:

* Firewall rules
* Restricted database access
* Separate administrative credentials
* Backups
* Account security
* Monitoring
* Service isolation
* Network security

Do not expose SQL Server or other internal services to the public Internet unless there is a specific reason to do so.

---

# 2. Server Architecture

A Mabinogi server is not a single executable.

The complete environment consists of several services that communicate with each other.

## Component Overview

| Component               | Purpose                                             | Required |
| ----------------------- | --------------------------------------------------- | -------- |
| **Authenticator**       | Handles authentication/account-related operations   | Yes      |
| **XMLDB**               | Provides database access to the server applications | Yes      |
| **LoginServer**         | Handles player login/session processing             | Yes      |
| **Coordinator**         | Coordinates server/channel information              | Yes      |
| **GameServer**          | Handles the game world and gameplay systems         | Yes      |
| **NPCClient**           | Provides NPC/world simulation and processing        | Yes      |
| **Messenger**           | Provides messaging functionality                    | Optional |
| **PHP Account Creator** | Provides a web interface for creating accounts      | Optional |
| **SQL Server**          | Stores persistent game data                         | Yes      |
| **Client**              | Player-facing game application                      | Yes      |

The server files used by this guide include the following major components:

```text
auth/
xmldb/
loginserver/
coordinator/
gameserver/
npcclient/
```

Additional components such as Messenger and a PHP account creator can be added when required.

---

## Startup Order

The services should generally be started in dependency order:

```text
SQL Server
    ↓
Authenticator
    ↓
XMLDB
    ↓
LoginServer
    ↓
Coordinator
    ↓
GameServer
    ↓
NPCClient
    ↓
Player Client
```

The exact startup timing can vary between environments.

The important concept is that a service should not be expected to communicate with another service that has not finished initializing.

---

## How a Login Works

A simplified connection flow looks like this:

```text
                 ┌─────────────┐
                 │    Client   │
                 └──────┬──────┘
                        │
                        ▼
                ┌───────────────┐
                │ Authenticator │
                └───────┬───────┘
                        │
                        ▼
                ┌──────────────┐
                │ LoginServer  │
                └───────┬──────┘
                        │
                        ▼
                ┌──────────────┐
                │ Coordinator  │
                └───────┬──────┘
                        │
                        ▼
                ┌──────────────┐
                │ GameServer   │
                └───────┬──────┘
                        │
                        ▼
                ┌──────────────┐
                │  NPCClient   │
                └──────────────┘
```

Meanwhile, the server components use XMLDB to access SQL Server:

```text
Auth
  │
LoginServer
  │
GameServer ───► XMLDB ───► SQL Server
  │
NPCClient
```

This distinction is useful when troubleshooting.

For example:

* A failed password check may involve Authenticator or the database.
* A successful login followed by a world-loading failure may involve Coordinator, GameServer, or NPCClient.
* NPCs failing to react may indicate an NPCClient problem rather than a login problem.

---

# 3. Requirements

## Software

The environment documented by this guide uses Windows and Microsoft SQL Server.

### Database Software

* Microsoft SQL Server 2022
* Microsoft SQL Server 2005 for legacy workflows
* SQL Server 2005 SP4 where required
* SQL Server Management Studio

### Server and Development Tools

* Mabinogi G20 server files
* G20 Unfixed SQL
* G20 Fixed SQL
* `uiupload.php`
* G20 DB Server MySQL 8 Alternative
* MabiPack / MabiPacker
* DNSpy
* Hex editor
* WinMerge
* XAMPP or another PHP-capable web server

### Useful Tools

* [MabiPack](https://github.com/logue/MabiPack)
* [DNSpy](https://github.com/dnspy/dnspy)
* [WinMerge](https://winmerge.org/)
* SQLBackupAndFTP

---

## Server Files

The server environment requires the appropriate G20 server files and database files.

The database preparation process described later uses:

```text
G20 Unfixed SQL
G20 Fixed SQL
```

The fixed SQL is applied over the unfixed SQL so that duplicate definitions are replaced by the fixed versions.

---

## Client Files

The documented client workflow uses:

* G20 Client Hotfix
* ProjectM200JP Client
* Language Patch
* Appropriate Mabinogi client files
* Steam files when legacy files need to be retrieved through Steam depots

Client and server versions should be kept compatible.

See [Version Compatibility](#19-version-compatibility).

---

# 4. Recommended Directory Layout

A consistent directory structure makes troubleshooting significantly easier.

A possible layout is:

```text
C:\mabinogi\
│
├── client\
│
└── server\
    │
    ├── auth\
    ├── xmldb\
    ├── loginserver\
    ├── coordinator\
    ├── gameserver\
    ├── npcclient\
    └── messenger\
```

The exact location does not have to be `C:\mabinogi`.

If a different location is used, update every configuration and batch file accordingly.

---

# 5. Preparing Windows

## SQL Server

Open:

```text
SQL Server Configuration Manager
```

Enable the required SQL Server services.

Set:

* **SQL Server** → Automatic startup
* **SQL Server Browser** → Automatic startup

Then navigate to:

```text
SQL Server Network Configuration
└── Protocols for MSSQLSERVER
```

Enable:

```text
TCP/IP
```

Open the TCP/IP properties and check the **IP Addresses** tab.

Under `IPAll`, configure:

```text
TCP Port = 1433
```

Restart SQL Server after changing the networking configuration.

---

## Manual File Preparation

Before configuring the server, prepare the SQL files.

Create a temporary workspace:

```text
G20-SQL\
├── Unfixed\
└── Working\
```

Copy the G20 Unfixed SQL files into the working directory.

Then extract the G20 Fixed SQL files over the same directory.

When Windows asks whether existing files should be overwritten, allow the fixed versions to replace the originals.

This produces a combined SQL workspace containing the fixed definitions.

---

## Symbolic Links

Some server components use duplicate copies of the same game data.

Instead of maintaining multiple independent copies, Windows symbolic links can be used.

Example:

```cmd
mklink /d "C:\mabinogi\server\somepath\data" "C:\mabinogi\shared\data"
```

Symbolic links are optional.

### Advantages

* Saves disk space
* Keeps duplicate files synchronized
* Reduces accidental differences between server components

### Disadvantages

* Can make the directory structure less obvious
* Can complicate backups
* Can make troubleshooting confusing if the user does not realize a directory is a link

For a first installation, ordinary directories may be easier to understand.

---

# 6. Database Installation

## SQL Server Configuration

The G20 environment uses SQL Server databases for persistent server data.

Before restoring the databases:

1. Start SQL Server.
2. Confirm TCP/IP is enabled.
3. Confirm SQL Server is listening on the expected port.
4. Start SQL Server Management Studio.
5. Verify that the SQL instance can be accessed.

---

## Restoring Databases

Move the required `.bak` files into an accessible backup directory.

Open SQL Server Management Studio.

Navigate to:

```text
Databases
```

Right-click:

```text
Restore Database...
```

Choose:

```text
From Device
```

Select the appropriate `.bak` file.

Set the destination database name to match the database expected by the server configuration.

---

## Logical File Names

When restoring multiple databases, SQL Server may attempt to reuse the same physical `.mdf` and `.ldf` paths.

This can cause collisions.

In the restore dialog, open the **Files** or **Options** area and verify the physical file locations.

If necessary, rename the physical/logical paths so each database receives unique filenames.

For example:

```text
database.mdf
database_1.mdf
database_2.mdf
```

and:

```text
database.ldf
database_1.ldf
database_2.ldf
```

Do not remove the `.mdf` or `.ldf` extensions.

---

## Database Connection Configuration

Many of the server executables obtain their database configuration from XML configuration files.

If the server reports an unknown connection, inspect the executable's expected connection name.

DNSpy can be useful when the required connection name is not obvious.

---

## XMLDB `config.xml`

The XMLDB configuration should contain the required database connection profiles.

A G20 configuration may contain entries such as:

```text
account
accountref
character
bank
prop
guild
websynch
itemidpool
charidpool
propidpool
loginidpool
guildidpool
bididpool
castle
house
memo
chronicle
ruin
shopadvertise
houseguestbook
dungeonrank
channelingkeypool
promotionrank
mailbox
farm
bid
event
worldmeta
wine
countryreport
loginoutreport
husky
privatefarm
facilityidpool
privatefarmrecommend
scrapbook
commerce
commercesystem
recommend
commercecriminal
goldlog
linkedapcharacter
equipmentcollection
soulmate
personalranking
setinfo
mabinovel
mabinovelboard
helppointrank
inviteevent
defaultconnection
```

The exact list depends on the server build.

---

## Authenticator `config.xml`

The Authenticator configuration maps additional SQL connections and item-shop information.

Example structure:

```xml
<sql>
    <connections>
        <fantasylifeclub></fantasylifeclub>
        <premiumpack></premiumpack>
        <pceventcoupon></pceventcoupon>
        <charactercard></charactercard>
        <petcard></petcard>
        <gift></gift>
        <freeservice></freeservice>
        <nexonidmap></nexonidmap>
        <passwordchange2010></passwordchange2010>
        <webdb></webdb>
    </connections>
</sql>

<itemshop gameNumber="9">
    <domains domainNumber="9" serverName="mabicn27"/>
    <sql
        server="127.0.0.1"
        database="db_shop_sync"
        user="mabishop"
        password="password"/>
</itemshop>
```

Replace database credentials with the credentials used by your environment.

---

## DB_XMLServer

Open:

```text
DB_XMLServer\_config.xml
```

Use the validated connection information from this file when creating:

```text
DB_XMLServer\config.xml
```

A typical server value may resemble:

```text
COMPUTER_NAME\INSTANCE_NAME
```

For example:

```text
Jon_Laptop\SQLExpress
```

Ensure that each connection maps to the correct restored database.

The documented environment may use:

```text
User: sa
```

with the corresponding SQL Server administrator password.

---

# 7. Server Configuration

## Configuration File Reference

Several configuration files appear throughout the G20 environment.

| File              | General Purpose                   |
| ----------------- | --------------------------------- |
| `config.xml`      | Database/service configuration    |
| `ServerInfo.ini`  | Server/channel information        |
| `server.ini`      | Server runtime configuration      |
| `NPCClient.xml`   | NPCClient configuration           |
| `features.xml`    | Feature/runtime configuration     |
| `ChannelInfo.xml` | Channel routing information       |
| `dungeondb2.xml`  | Dungeon configuration             |
| `urls.xml`        | Client web/UI endpoints           |
| `language.pack`   | Localized client/server resources |

Because several copies of the same filename may exist, always verify **which executable uses the file you are editing**.

---

# 8. Client Configuration

## Language Files

Mabinogi's client language resources are stored inside `.pack` files.

The G20 translation workflow uses:

```text
lang_eng.pack
language.pack
```

The client and server should use compatible language resources.

---

# 9. Translation and Language Packs

## Understanding Language Packs

The translation process involves:

1. Extracting the existing language pack.
2. Extracting localized resources.
3. Merging the desired files.
4. Repacking the resulting directory.
5. Installing the resulting `language.pack`.
6. Clearing server caches.
7. Testing the client.

---

## Extraction

Create two working directories:

```text
Downloads\language
Downloads\lang_eng
```

Copy:

```text
client\package\lang_eng.pack
server\gameserver\package\language.pack
```

into your working directory.

Unpack both archives.

---

## Merging Localized Data

Extract the contents of `locala.7z` into:

```text
Downloads\language
```

The resulting structure should contain:

```text
Downloads\language\data\local
```

Copy the desired `local` directory into:

```text
Downloads\language\data
```

Allow the existing files to be overwritten.

The resulting localized files may include resources such as:

```text
china.world.txt
```

and related scripts.

Copy the resulting local data into the server's data directory:

```text
C:\mabinogi\server\gameserver\data
```

---

## Clearing the Cache

After modifying language resources, clear:

```text
C:\mabinogi\server\gameserver\cache
```

This is important because stale cached data can make it appear as though a translation change did not work.

---

## Repacking

Open MabiPack.

Choose:

```text
Pack Folder
```

Use:

```text
Input:
Downloads\language\data

Output:
Downloads\lang_eng.pack
```

Recommended parameters from this environment:

```text
Version: 243
Compression Level: 1
```

Overwrite the existing output when necessary.

---

## Installing the Finished Pack

Rename the resulting file:

```text
lang_eng.pack
```

to:

```text
language.pack
```

Copy it to the relevant locations:

```text
C:\mabinogi\client\package\language.pack
C:\mabinogi\server\gameserver\package\language.pack
C:\mabinogi\server\npcserver\package\language.pack
```

Make a backup of the original files before replacing them.

---

# 10. UI Upload Service

Some client UI settings can be uploaded to and downloaded from a web service.

## PHP Endpoint

A simple `UiUpload.php` implementation is:

```php
<?php

$charId = $_POST['char_id'];
$nameServer = $_POST['name_server'];
$uiLoadSuccess = $_POST['ui_load_success'];

$group = substr($charId, -3);

$file_tmp = $_FILES["ui"]["tmp_name"];

$target_dir = "ui/" . $nameServer . "/" . $group . "/";
$target_file = $target_dir . basename($_FILES["ui"]["name"]);

if (!is_dir($target_dir)) {
    mkdir($target_dir, 0755, true);
}

if (move_uploaded_file($_FILES["ui"]["tmp_name"], $target_file)) {
    echo "The file " . basename($_FILES["ui"]["name"]) . " has been uploaded.";
} else {
    echo "Sorry, there was an error uploading your file.";
}
?>
```

This should be treated as a development-oriented example.

If exposing it to untrusted users, additional validation and security controls should be implemented.

---

# 11. Configuring `urls.xml`

Open the client package:

```text
ProjectM200JPClient\Client\package\198_full.pack
```

Use MabiPacker's **Unpack** functionality.

Open:

```text
data\db\urls.xml
```

Locate the appropriate locale section.

For a local server, the configuration may resemble:

```xml
UploadUIPage="http://127.0.0.1/UiUpload.php"
DownloadUIAddress="http://127.0.0.1/ui/"
```

Save the modified file to:

```text
ProjectM200JPClient\Client\data\db\urls.xml
```

---

## Verification

Launch the client.

Test:

1. Log in.
2. Change the hotbar or another UI layout.
3. Move or resize a UI element.
4. Exit the client.
5. Log back in.
6. Verify that the UI configuration is restored.

If the settings are not restored, troubleshoot:

* PHP server
* URL configuration
* Directory permissions
* Character ID
* Server name
* Uploaded files
* Client cache

---

# 12. Starting the Server

## Startup Order

Start the components in approximately this order:

```text
Authenticator
XMLDB
LoginServer
Coordinator
GameServer
NPCClient
```

Allow each service time to initialize before starting the next one.

---

## `startall.bat`

A simple startup script can automate the process:

```batch
@echo off

start "" "C:\mabinogi\server\auth\authenticator.exe" "GM KR Test, China"
timeout /t 5

start "" "C:\mabinogi\server\xmldb\xmldb.exe" "GM KR Test, China"
timeout /t 5

start "" "C:\mabinogi\server\loginserver\loginserver.exe" "GM KR Test, China"
timeout /t 3

start "" "C:\mabinogi\server\coordinator\coordinator.exe" "GM KR Test, China"
timeout /t 3

start "" "C:\mabinogi\server\gameserver\gameserver.exe" "GM KR Test, China"
timeout /t 10

start "" "C:\mabinogi\server\npcclient\npcclient.exe" "GM KR Test, China"
```

The documented environment uses:

```text
GM KR Test, China
```

for server-side test startup.

The player client uses:

```text
Regular, China
```

instead.

These parameters should match the intended server/client configuration.

---

# 13. First Boot Checklist

Before troubleshooting individual systems, confirm the basic server is operational.

```text
[ ] SQL Server is running
[ ] Required databases are restored
[ ] Authenticator starts
[ ] XMLDB starts
[ ] LoginServer starts
[ ] Coordinator starts
[ ] GameServer starts
[ ] NPCClient starts
[ ] NPCClient completes initialization
[ ] Player account exists
[ ] Client starts
[ ] Client can authenticate
[ ] Player can select a character
[ ] Player can enter the world
[ ] Player can move
[ ] NPCs respond
[ ] Character data saves
```

A successful NPCClient initialization should eventually produce:

```text
SYS> ---------- Processing-Commands End ----------
```

Do not assume that a successful login means the server has completely finished initializing.

---

# 14. Accounts and GameMaster Setup

## NPC Account

Use `xmldb_accountmanager` to create the NPC processing account.

The documented environment uses:

```text
Username: npc1
Password: fpswl
Authority: npc
```

The corresponding MD5 representation documented by the original setup is:

```text
AD899A74D1AA830BF77625F4328118DC
```

Verify that the account information matches:

```text
npcclient\NPCClient.xml
```

---

## GameMaster Account

The documented test account uses:

```text
Username: admin
Password: admin
Authority: boss
```

For a development environment this can be convenient.

For anything beyond local testing, use a unique password.

---

# 15. NPCClient Initialization

NPCClient is an important part of the G20 environment because it provides world/NPC processing.

## Initialization Procedure

1. Start the server.
2. Launch:

```text
243_C\client start.bat
```

3. Log in using:

```text
npc1
```

4. Create the default NPC character:

```text
npc
```

5. Enter the world.
6. Open the command terminal.
7. Run:

```text
>move /r:15 /x:1000 /y:1000
>set_condition /a:23
```

8. Close the processing client wrapper.
9. Watch the NPCClient server window.

Wait for:

```text
SYS> ---------- Processing-Commands End ----------
```

This indicates that the expected processing initialization stage has completed.

---

# 16. Player Client Initialization

After NPCClient has been initialized:

1. Create a normal player account.
2. Check:

```text
gameserver\server.ini
```

3. Check other relevant `server.ini` files.
4. Ensure the intended client configuration uses:

```text
Regular, China
```

rather than:

```text
GM KR Test, China
```

5. Launch:

```text
start.bat
```

6. Start:

```text
client.exe
```

7. Log in.
8. Create a character.
9. Complete the initial tutorial areas.

Completing the initial areas allows the server to establish the expected character data.

---

# 17. GameMaster Testing

If the `admin` account is being used as a GM test account, the documented setup includes:

```text
>set_title /add /id:60000
```

GM functionality should generally be tested on a development character rather than on a normal player account.

---

# 18. Server Administration

## Server Startup and Shutdown

A simple startup process is:

```text
SQL Server
↓
Auth
↓
XMLDB
↓
LoginServer
↓
Coordinator
↓
GameServer
↓
NPCClient
```

When shutting down, allow the server applications to close cleanly before stopping SQL Server.

Always consider database integrity before forcibly terminating a running service.

---

# 19. Changing Server and Channel Names

The default environment may contain names such as:

```text
TEST_WORLD
mabilocalserver
```

To change them, inspect:

```text
gameserver\data\local\xmlchnnelindexinfo.china.txt
```

Search for the existing server/world name.

Also inspect:

```text
ServerInfo.ini
NPCClient.xml
server.ini
```

The relevant files may exist in multiple server directories.

When changing a server name, update **all required copies**.

---

# 20. Database Administration

## Backups

Before making direct database modifications:

1. Stop the affected server service if appropriate.
2. Back up the relevant database.
3. Record the intended change.
4. Make the modification.
5. Test the server.
6. Keep the backup until the change has been verified.

Never assume a database modification can be easily reversed.

---

## Removing a Corrupt Item

If a corrupt or invalid item prevents a character from functioning correctly, it may be possible to remove the item directly from SQL Server.

The documented item tables include:

```text
Charitemlarge
Charitemhuge
Charitemsmall
```

Before deleting anything:

1. Identify the item's Class ID.
2. Locate the character.
3. Confirm the item belongs to the correct character.
4. Check contextual information such as creation timestamps.
5. Check color or other identifying properties.
6. Make a database backup.
7. Delete only the intended row.

The goal is to avoid accidentally deleting identical items belonging to other characters.

---

# 21. Deep Database Corrections

When server binaries and database schemas come from different revisions, database errors may occur.

A debugging approach is:

1. Identify the database operation producing the error.
2. Inspect the relevant executable with DNSpy.
3. Determine the data types expected by the application.
4. Compare those types against the SQL columns.
5. Identify missing stored procedures or handlers.
6. Correct the database schema only after creating a backup.
7. Test the affected server function.

The original environment notes that approximately three missing procedure handlers may need to be recreated for certain schema mismatches.

---

# 22. Modifying Game Data

One of the advantages of a private-server environment is the ability to modify game data.

Common modification areas include:

```text
XML
Scripts
Skills
Events
Localization
Database
Client binaries
```

---

## XML Data

Common XML data locations include:

```text
gameserver\data\db\
gameserver\data\local\
```

Examples include:

```text
dungeondb2.xml
ChannelInfo.xml
skillinfo.xml
skillleveldescription.xml
basiceventlist.xml
```

Always make a backup before modifying XML data.

---

## Scripts

G20 scripts may be stored under directories such as:

```text
gameserver\data\script\
```

Dungeon scripts are an example:

```text
gameserver\data\script\dungeon2\
```

When changing scripts:

1. Make a backup.
2. Identify all related scripts.
3. Search for references to the same variable or event.
4. Modify the minimum necessary code.
5. Restart the relevant service.
6. Test the feature from the beginning.

---

# 23. Example: Dungeon Password Fix

A documented issue involves several underground waterway dungeon scripts.

The affected files include:

```text
701015_bossmission2reddragon.mint
701016_bossmission3claimhsolas.mint
730103_eventclaimhsolas.mint
792203_claimhsolas.mint
793004_investigatecanal.mint
793005_investigatecanal2.mint
793006_meetnuadha2.mint
```

The original logic contains:

```javascript
_dungeon.SetData(`password`, password2);
```

The documented workaround replaces the relevant logic with:

```javascript
password1 = "Secret";
password2 = " Password";
string password3 = password1 + password2;

_dungeon.SetData(`password`, password3);
```

This makes the dungeon password evaluate to:

```text
Secret Password
```

This is an example of a broader troubleshooting technique:

> When multiple scripts participate in the same feature, fixing only one script may not be sufficient.

---

# 24. Example: Adding Flown Sky Lantern

The Flown Sky Lantern feature demonstrates how a single feature may require changes across several data systems.

The documented modification involves:

```text
skillinfo.xml
skillleveldescription.xml
basiceventlist.xml
basiceventlist.china.txt
```

### Skill Definition

Add the appropriate skill entries to:

```text
skillinfo.xml
```

including the documented skill IDs:

```text
50070
50071
```

### Skill Level Definition

Add the corresponding entry to:

```text
skillleveldescription.xml
```

### Event Definition

Add:

```xml
<Event
    name="pungdeung_2015"
    start_msg="_LT[xml.basiceventlist.1049]"
    progress_msg="_LT[xml.basiceventlist.1050]"
    end_msg="_LT[xml.basiceventlist.1051]" />
```

### Localization

Add:

```text
1049    Start the Flown Sky Lantern Event.
1050    The Flown Sky Lantern Event is in progress.
1051    End the Flown Sky Lantern Event.
```

This illustrates an important development principle:

```text
Feature
├── Data definition
├── Skill definition
├── Runtime behavior
├── Event definition
└── Localization
```

---

# 25. Client Binary Modifications

Some client fixes require modifying binary data.

For example, the documented `10000 Gold` display correction uses:

```text
patch2.dat
```

and a hex editor.

Before making binary modifications:

1. Make a copy of the original file.
2. Record the exact file version.
3. Verify the search bytes exist.
4. Make the replacement.
5. Save the modified file separately.
6. Test the client.
7. Keep the original available for rollback.

The documented replacement blocks are:

```text
Routine 3

Search:
8B 45 10 48 83 F8 07 0F 87 C6 01 00 00

Replace:
E9 8F 01 00 00 90 90 0F 87 C6 01 00 00
```

```text
Routine 4

Search:
8B 49 50 81 C1 E7 03 00 00 B8 D3 4D 62 10 F7 E1 8B C2 C1 E8 06 C3

Replace:
8B 49 50 81 C1 00 00 00 00 B8 D3 4D 62 10 F7 E1 8B C2 8B C1 C3 90
```

The longer Routine 5 replacement should likewise only be applied to the matching client build.

**Do not apply binary patches to a different client version without first verifying the byte sequence.**

---

# 26. Reverse Engineering and Development Tools

## DNSpy

Useful for:

* Finding configuration strings
* Identifying database connections
* Investigating exceptions
* Understanding server behavior
* Finding feature flags
* Identifying database operations

---

## MabiPack / MabiPacker

Useful for:

* Extracting `.pack` files
* Inspecting client data
* Comparing client versions
* Editing localization
* Repacking modified data

---

## WinMerge

Useful for comparing:

* Different server builds
* Different client versions
* Translation files
* XML files
* Configuration changes

---

## Hex Editor

Useful for:

* Binary patches
* Client fixes
* Searching known byte sequences
* Comparing binary versions

---

## Additional References

Useful development tools mentioned by the original environment include:

* Morrighan
* Fetitor
* Mabi DataHelper

Command references are also available in the documented command spreadsheets.

---

# 27. Networking

Networking becomes increasingly important when moving from a localhost development environment to LAN or Internet access.

## Address Types

### Localhost

```text
127.0.0.1
```

Means:

> This computer.

Use it when both communicating applications are running on the same machine.

### LAN Address

Example:

```text
192.168.1.100
```

Use this when another computer on the local network needs to connect.

### Public Address

A public IP or DNS hostname can be used when clients outside the LAN need to connect.

---

## Troubleshooting Network Problems

When a client cannot connect, determine where the connection stops.

```text
Client
 ↓
Network
 ↓
Authenticator
 ↓
LoginServer
 ↓
Coordinator
 ↓
GameServer
```

Do not immediately assume that the database is responsible for a connection failure.

Check the earliest component that fails.

---

# 28. Troubleshooting

## Troubleshooting Method

When something fails, avoid immediately applying unrelated fixes.

Use this process:

### 1. Identify the symptom

Example:

> Login succeeds but the game world never loads.

### 2. Identify the layer

```text
Client
Network
Authentication
Login
Coordinator
GameServer
NPCClient
XMLDB
SQL
```

### 3. Check logs

Look at the console/log output from the component closest to the failure.

### 4. Check configuration

Verify:

* Server names
* Database names
* Ports
* IP addresses
* Credentials
* Paths
* Feature configuration

### 5. Check dependencies

Make sure required services are running.

### 6. Reproduce the problem

Try the same action again after making only one change.

### 7. Record the fix

If you discover a new workaround, document:

```text
Problem
Cause
Affected version
Files changed
Fix
Verification
```

This makes future troubleshooting much easier.

---

# 29. Server Does Not Start

Check:

```text
[ ] SQL Server is running
[ ] Configuration files exist
[ ] Database names are correct
[ ] Database credentials are correct
[ ] Required ports are available
[ ] Required DLLs/files exist
[ ] Server paths are correct
[ ] Correct server build is being used
```

If an executable closes immediately, run it manually rather than through `startall.bat` so the error remains visible.

---

# 30. Missing System Parameters

If maps, commerce, or currency-related features do not work correctly, verify the feature configuration across:

```text
Login
Game
NpcClient
Coordinator
```

The documented configuration includes:

```ini
file://data/features.xml=Regular, China
```

Check that the relevant services are loading the intended feature configuration.

---

# 31. Dungeon Pass Problems

If the Dungeon Unlimited Pass does not work, inspect:

```text
gameserver\data\db\dungeondb2.xml
```

The documented issue can occur when legacy and 2016 renewal dungeon definitions conflict.

For the affected dungeon entries, compare:

```xml
dungeonpassable="true"
```

and:

```xml
dungeonpassable="false"
```

The documented workaround changes the relevant legacy/renewal entries so that the intended dungeon rules are used.

Always back up the file first.

---

# 32. Tin's Magic Stone Does Not Work

Check:

```text
ServerInfo.ini
```

in the relevant server directories.

Verify that:

```ini
CHANNELGROUPFILE = data\db\ChannelInfo.xml
```

is present and correctly configured.

This setting determines the channel routing information used by the affected feature.

---

# 33. Client Does Not Launch After Unpacking

If unpacking or modifying a `.pack` file causes the client to stop launching, verify the resulting directory structure.

The documented server structure expects localized files under:

```text
gameserver\data\local\
```

Check for:

* Incorrect directory nesting
* Missing files
* Incorrect pack version
* Corrupted archive
* Client/server version mismatch
* Incorrect language pack structure

Restore the original pack if necessary to determine whether the modification caused the problem.

---

# 34. Delayed Monster Recognition

If monsters take several seconds to recognize or react to players, inspect the NPCClient processing rate.

The documented environment considers sustained processing below approximately:

```text
35 FPS
```

a potential indication that the NPCClient processing loop is overloaded.

Possible causes include:

* Insufficient CPU resources
* Virtualized environments
* Nested virtualization
* Other processes consuming CPU
* Incorrect NPCClient configuration

The original setup recommends testing on dedicated bare-metal Windows hardware if the NPCClient cannot maintain adequate processing performance.

---

# 35. World Entry Hangs

If:

* authentication succeeds,
* the player logs in,
* but the client remains stuck while entering the world,

check the NPCClient window.

The server may still be completing initialization.

Look for:

```text
SYS> ---------- Processing-Commands End ----------
```

If this message has not appeared, allow NPCClient initialization to complete before assuming the client is broken.

---

# 36. Known Bugs and Limitations

The documented G20 environment contains several known issues.

## Burning with Vengeance

The Sword of Vengeance encounter may fail to generate its enemies.

The documented affected script is:

```text
731009_milliatraning01.mint
```

The required fix involves modifying the creature spawning logic.

---

## Carpentry

Carpentry benches may fail to register interactions correctly.

This is currently documented as a server limitation requiring further investigation.

---

## Homestead Farming

Poisonous herb cultivation within a personal homestead may result in:

```text
unauthorized action
```

This is currently documented as an unresolved limitation.

---

# 37. Version Compatibility

Mabinogi server environments are particularly sensitive to version differences.

Keep track of:

```text
Server build
Client build
Language pack version
NPCClient version
Database revision
Pack version
Script revision
```

A mismatch can produce problems such as:

* Missing XML data
* Database errors
* Client crashes
* Broken quests
* Incorrect localization
* Missing skills
* Incorrect dungeon behavior
* Broken scripts

When investigating a problem, record the exact versions involved.

---

# 38. Version Tracking Template

Use a table like this when maintaining your own server:

| Component     | Version/Build | Date Tested | Notes |
| ------------- | ------------- | ----------- | ----- |
| Server        | G20           |             |       |
| Client        |               |             |       |
| Database      |               |             |       |
| Language Pack |               |             |       |
| NPCClient     |               |             |       |
| MabiPack      |               |             |       |
| SQL Server    |               |             |       |
| Windows       |               |             |       |

This makes future troubleshooting much easier.

---

# 39. Common Mistakes

## Mixing Client Versions

Do not assume that a file from one client build will work with another.

---

## Editing Only One Configuration Copy

A configuration file may exist in several server directories.

Always determine which executable reads the file.

---

## Forgetting the NPCClient

A server may successfully authenticate players while still being unable to enter the game world because NPCClient has not finished initialization.

---

## Forgetting the Cache

After modifying language data, clear:

```text
gameserver\cache
```

---

## Modifying the Database Without a Backup

Always create a backup before direct database changes.

---

## Applying a Binary Patch to the Wrong Client

Always verify the expected byte sequence before applying a hex modification.

---

# 40. Quick Start

For experienced users, the basic workflow is:

```text
1. Prepare Windows
2. Install SQL Server
3. Restore the G20 databases
4. Prepare server files
5. Configure XMLDB
6. Configure Authenticator
7. Configure LoginServer
8. Configure Coordinator
9. Configure GameServer
10. Configure NPCClient
11. Configure client
12. Start server services
13. Initialize NPCClient
14. Create NPC account
15. Create player account
16. Launch client
17. Enter the world
18. Verify NPC processing
19. Create a database backup
```

For explanations of each stage, use the corresponding chapter rather than treating this checklist as a substitute for the full guide.

---

# 41. Appendix: Steam Client Extraction

Legacy Mabinogi client files can sometimes be obtained through Steam depot downloads.

The documented workflow uses a Steam manifest patching utility.

Open Steam's console using:

```text
steam://open/console
```

The general Steam depot command is:

```text
download_depot <appid> <depotid> [<new manifestid>] [<old manifestid>]
```

The documented examples include:

### Older Client Build

```text
download_depot 212200 212201 5378056672283508653
```

### Latest Documented Release Branch

```text
download_depot 212200 212201 1110034208523718321
```

### Comparing Versions

```text
download_depot 212200 212201 1110034208523718321 1877343873669484515
```

Steam typically places downloaded depot content under a directory resembling:

```text
C:\Program Files (x86)\Steam\steamapps\content\
```

The console output will identify the exact destination.

The downloaded files can then be compared against another client build using tools such as WinMerge or MabiPack.

---

# 42. Appendix: Legacy SQL Server Installation

Some older workflows require SQL Server 2005.

Legacy software can be difficult to install on modern Windows versions.

## Error 1603

A documented problem is:

```text
MSI Error 1603
```

when attempting to install legacy SQL Server components.

The original environment documents a workaround involving a Windows 7 64-bit virtual machine.

The general process described is:

1. Create an isolated Windows 7 64-bit virtual machine.
2. Install SQL Server 2005 Express.
3. Install SQL Server 2005 SP4.
4. Obtain the required legacy binaries.
5. Run the SQL Server 2005 installation on the host.
6. Replace the problematic binaries when the installer reaches the affected stage.
7. Retry the installation.
8. Enable mixed-mode authentication if required.

The relevant binaries documented by the original setup are:

```text
sqlservr.exe
sqlos.dll
```

### Important

This is a legacy workaround and should only be used when the G20 environment actually requires SQL Server 2005 functionality.

Prefer a supported/current SQL Server version when the server software permits it.

---

# 43. Administrative Command References

The original environment references external command spreadsheets containing:

* GM commands
* Command parameters
* Operational information
* Layout/system information

Keep these references alongside the guide if they remain available.

When documenting commands, record them in a consistent format:

```text
Command:
>example

Purpose:
What the command does.

Syntax:
>example /argument:value

Arguments:
- argument — description

Example:
>example /argument:value

Notes:
Any known limitations.
```

This format makes command documentation much easier to search.

---

# 44. Recommended Modification Workflow

When modifying the server, use the following workflow:

```text
Identify feature
      ↓
Find relevant files
      ↓
Back up files
      ↓
Determine dependencies
      ↓
Make one change
      ↓
Restart affected service
      ↓
Test feature
      ↓
Record result
      ↓
Repeat
```

Avoid changing ten unrelated files at once.

When something breaks, knowing which change caused the problem is much more valuable than simply having a collection of modifications that happen to work.

---

# 45. Recommended Backup Structure

A simple backup structure could be:

```text
backups\
│
├── database\
│   ├── account\
│   ├── character\
│   └── game\
│
├── server\
│   ├── config\
│   ├── scripts\
│   └── data\
│
└── client\
    ├── package\
    └── modified\
```

For major changes, create a dated backup:

```text
backup_2026-09-18_before-language-update\
```

This makes rollback straightforward.

---

# 46. Guide Maintenance

Because private-server software is often undocumented and version-specific, this guide should be treated as a living document.

When discovering a new fix, add:

```markdown
### Problem

Describe the symptom.

### Environment

Describe the server/client version.

### Cause

Explain what was discovered.

### Fix

List the exact modification.

### Verification

Explain how success was confirmed.

### Notes

Mention whether the fix is version-specific.
```

This prevents the guide from becoming another collection of unexplained fixes.

---

# 47. Changelog

## Initial Version

* Documented G20 server architecture
* Documented SQL Server setup
* Documented database restoration
* Documented server configuration
* Documented client configuration
* Documented language-pack workflow
* Documented NPCClient initialization
* Documented GM account setup
* Added troubleshooting procedures
* Added database maintenance information
* Added client modification examples
* Added known bugs and limitations
* Added Steam depot extraction appendix

---

# 48. Final Installation Checklist

Before considering the environment complete, verify:

## Database

```text
[ ] SQL Server installed
[ ] SQL Server running
[ ] TCP/IP enabled
[ ] Port configured
[ ] Required databases restored
[ ] Database connections tested
[ ] Initial backup created
```

## Server

```text
[ ] Authenticator configured
[ ] XMLDB configured
[ ] LoginServer configured
[ ] Coordinator configured
[ ] GameServer configured
[ ] NPCClient configured
```

## Client

```text
[ ] Correct client version
[ ] Correct language pack
[ ] Correct server URLs
[ ] Client starts
[ ] Client authenticates
```

## NPCClient

```text
[ ] NPC account created
[ ] NPCClient initialized
[ ] NPC character created
[ ] Processing completed
```

## Player

```text
[ ] Player account created
[ ] Character created
[ ] Character can enter world
[ ] Character can move
[ ] NPCs respond
[ ] Character data saves
```

## Administration

```text
[ ] GM account tested
[ ] Database backup created
[ ] Server startup script tested
[ ] Server shutdown procedure tested
[ ] Configuration backups created
```

---

# 49. Summary

A Mabinogi G20 private server is best understood as a collection of interconnected systems rather than a single server executable.

The major layers are:

```text
Client
   │
   ▼
Authentication
   │
   ▼
Login
   │
   ▼
Coordinator
   │
   ▼
GameServer
   │
   ├──────────────► XMLDB ──────────────► SQL Server
   │
   ▼
NPCClient
```

Once the architecture is understood, troubleshooting becomes considerably easier.

When something fails, determine **which layer failed first**, identify the configuration or data responsible, make a backup, change one thing at a time, and verify the result.

The installation procedures in this guide provide the practical path to a working G20 environment, while the administration, development, troubleshooting, and reference sections are intended to make the document useful after the initial installation is complete.
