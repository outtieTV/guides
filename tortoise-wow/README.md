# Turtle-WoW MaNGOS Server Guide — Windows

A guide to building, configuring, and running a **Turtle-WoW MaNGOS server on Windows**.

This guide is intended primarily for **local/LAN use**, development, and private testing. It covers compiling the server from source, installing its dependencies, preparing the MySQL databases, configuring the client, and troubleshooting common problems.

> **Important:** This guide uses specific versions of several dependencies and a specific Turtle-WoW client build. Newer versions may work, but they are not necessarily compatible with the source used by this guide.

---

# Table of Contents

* [1. What This Guide Covers](#1-what-this-guide-covers)
* [2. Understanding the Server](#2-understanding-the-server)
* [3. Prerequisites](#3-prerequisites)
* [4. Recommended Directory Layout](#4-recommended-directory-layout)
* [5. Required Software and Dependencies](#5-required-software-and-dependencies)
* [6. Preparing Windows](#6-preparing-windows)
* [7. Building OpenSSL](#7-building-openssl)
* [8. Installing zlib](#8-installing-zlib)
* [9. Building Recast/Detour](#9-building-recastdetour)
* [10. Installing SDL2](#10-installing-sdl2)
* [11. Building ACE](#11-building-ace)
* [12. Obtaining the Turtle-WoW Source](#12-obtaining-the-turtle-wow-source)
* [13. Configuring CMake](#13-configuring-cmake)
* [14. Building the MaNGOS Server](#14-building-the-mangos-server)
* [15. Installing Server Patches](#15-installing-server-patches)
* [16. Setting Up MySQL](#16-setting-up-mysql)
* [17. Configuring the Client](#17-configuring-the-client)
* [18. First Server Startup](#18-first-server-startup)
* [19. LAN Setup](#19-lan-setup)
* [20. Server Configuration](#20-server-configuration)
* [21. Server Administration](#21-server-administration)
* [22. Database Backups](#22-database-backups)
* [23. Customization](#23-customization)
* [24. Updating the Server](#24-updating-the-server)
* [25. Troubleshooting](#25-troubleshooting)
* [26. Frequently Asked Questions](#26-frequently-asked-questions)
* [27. Known Limitations](#27-known-limitations)
* [28. Quick-Start Checklist](#28-quick-start-checklist)
* [29. Glossary](#29-glossary)

---

# 1. What This Guide Covers

This guide covers building a Turtle-WoW MaNGOS server from source on **Windows x64**.

The general process is:

```text
Install development tools
        ↓
Install/build dependencies
        ↓
Obtain Turtle-WoW source
        ↓
Configure CMake
        ↓
Generate Visual Studio solution
        ↓
Build mangosd + realmd
        ↓
Install server patches
        ↓
Create MySQL databases
        ↓
Configure WoW client
        ↓
Start realmd
        ↓
Start mangosd
        ↓
Connect the client
```

The guide assumes that you want to build the server yourself rather than downloading precompiled server binaries.

## What this guide does not assume

You do not need to be an experienced C++ developer, but some familiarity with the following is helpful:

* Windows file management
* Command Prompt or PowerShell
* Visual Studio
* CMake
* Git
* Basic SQL
* Editing configuration files

---

# 2. Understanding the Server

Before installing anything, it helps to understand what the different components do.

## 2.1 The WoW Client

The WoW client is the game itself.

It connects to the server using the address specified in:

```text
realmlist.wtf
```

For a local server, this can be:

```text
set realmlist 127.0.0.1
```

---

## 2.2 `realmd.exe`

`realmd.exe` is the login/realm server.

It handles the initial authentication process and tells the client which realm/world server it should connect to.

A simplified connection looks like:

```text
WoW Client
    │
    │ Login
    ▼
realmd.exe
    │
    │ Realm information
    ▼
mangosd.exe
```

---

## 2.3 `mangosd.exe`

`mangosd.exe` is the world server.

It handles the actual game world, including things such as:

* NPCs
* creatures
* quests
* maps
* combat
* player characters
* world events
* gameplay systems

If `realmd.exe` is the login server, `mangosd.exe` is the server that actually runs the game world.

---

## 2.4 MySQL

MySQL stores the persistent server data.

Depending on the source revision, databases are generally divided into areas such as:

```text
Authentication / Realm
        │
        ├── Accounts
        └── Realm information

Characters
        │
        ├── Character data
        ├── Inventory
        └── Progress

World
        │
        ├── NPCs
        ├── Quests
        ├── Items
        ├── Spawns
        └── World data
```

The exact database names and structure are determined by the source tree and SQL files.

---

# 3. Prerequisites

## 3.1 Operating System

This guide targets:

* Windows 10/11
* 64-bit Windows
* x64 builds

Windows 11 is used for the examples.

---

## 3.2 Hardware

The server does not require particularly powerful hardware for a small LAN server.

A reasonable starting point is:

| Component | Recommendation               |
| --------- | ---------------------------- |
| CPU       | Modern 4-core or better      |
| RAM       | 8 GB minimum                 |
| RAM       | 16 GB recommended            |
| Storage   | SSD recommended              |
| Network   | Ethernet recommended for LAN |
| OS        | Windows 10/11 x64            |

Actual requirements depend on player count and server configuration.

---

# 4. Recommended Directory Layout

All paths in this guide are examples.

You can use different drives or folders if desired.

A convenient layout is:

```text
C:\
└── local\
    ├── openssl-1.1.1s\
    ├── zlib\
    ├── SDL\
    ├── recast-1.6.0\
    └── src\
        └── ACE\

F:\
└── Servers\
    └── turtlewow\
        ├── tortoise-wow-main\
        ├── tortoise-wow-build\
        └── TurtleWoW Client\
```

The important thing is to keep the locations organized and use the same paths consistently when configuring CMake.

> **Tip:** Keeping third-party dependencies under one directory such as `C:\local\` makes troubleshooting significantly easier.

---

# 5. Required Software and Dependencies

## 5.1 Development Tools

| Tool          | Version used by this guide | Purpose                         |
| ------------- | -------------------------: | ------------------------------- |
| Visual Studio |              2022 or later | C++ compiler                    |
| CMake         |                    3.25.1+ | Generate Visual Studio projects |
| Git           |                    Current | Download source                 |
| MySQL         |                        8.0 | Server database                 |

Install the **Desktop development with C++** workload in Visual Studio.

Make sure the Windows SDK and MSVC C++ tools are installed.

---

## 5.2 Third-Party Libraries

| Library       |            Version | Purpose                                |
| ------------- | -----------------: | -------------------------------------- |
| OpenSSL       |             1.1.1s | SSL/cryptographic functionality        |
| zlib          |              1.2.3 | Compression                            |
| SDL2          | Recent x64 release | Client/server supporting functionality |
| Recast/Detour |              1.6.0 | Navigation/pathfinding                 |
| ACE           |              8.0.5 | Networking/framework functionality     |

> **Version note:** These versions are intentionally documented. Do not automatically replace them with the newest available releases.

---

# 6. Preparing Windows

## 6.1 Install Visual Studio

Download Visual Studio from:

https://visualstudio.microsoft.com/

During installation, select:

* Desktop development with C++
* MSVC compiler
* Windows SDK
* CMake tools for Windows

After installation, verify that Visual Studio can create and build a basic C++ project.

---

## 6.2 Install CMake

Download CMake from:

https://cmake.org/download/

Install it so that CMake is available from the command line.

Verify:

```cmd
cmake --version
```

You should receive a version number.

---

## 6.3 Install Git

Install Git for Windows.

Verify:

```cmd
git --version
```

---

# 7. Building OpenSSL

This guide uses OpenSSL 1.1.1s.

Download the OpenSSL source and follow the Windows build instructions.

One useful reference for building OpenSSL, zlib, and related libraries is:

https://developers.lseg.com/en/article-catalog/article/how-to-build-openssl--zlib--and-curl-libraries-on-windows

Place the resulting installation somewhere such as:

```text
C:\local\openssl-1.1.1s
```

The resulting installation should contain the required libraries and DLLs.

For example:

```text
C:\local\openssl-1.1.1s\
├── bin\
├── include\
└── lib\
```

Depending on the build process, the exact filenames may differ.

## Verify

Add the OpenSSL `bin` directory to PATH if required and run:

```cmd
openssl version
```

---

# 8. Installing zlib

Download zlib 1.2.3:

https://sourceforge.net/projects/gnuwin32/files/zlib/1.2.3/

Install or extract it to:

```text
C:\local\zlib
```

Verify that the expected headers, libraries, and DLLs are present.

For example:

```text
C:\local\zlib\
├── bin\
├── include\
└── lib\
```

---

# 9. Building Recast/Detour

Download Recast/Detour 1.6.0.

Extract the source to:

```text
C:\local\src\recastnavigation-1.6.0
```

The project can be generated with CMake and then opened in Visual Studio.

## Build Configuration

Use:

```text
Configuration: Release
Platform:      x64
```

Build the required projects.

The resulting libraries should be placed somewhere such as:

```text
C:\local\recast-1.6.0\Release
```

The exact output structure can vary depending on how the solution was generated.

## Verify

Confirm that the expected Recast/Detour `.lib` files were produced.

---

# 10. Installing SDL2

Download an appropriate SDL2 x64 Visual Studio package from:

https://github.com/libsdl-org/SDL/releases

Extract it to:

```text
C:\local\SDL
```

For example:

```text
C:\local\SDL\
├── bin\
├── include\
└── lib\
```

The x64 library directory may be:

```text
C:\local\SDL\lib\x64
```

Add the SDL2 runtime directory to PATH:

```text
C:\local\SDL\bin
```

---

# 11. Building ACE

This guide uses:

```text
ACE 8.0.5
```

Download:

http://download.dre.vanderbilt.edu

Extract:

```text
ACE-8.0.5-full.zip
```

to:

```text
C:\local\src\ACE
```

---

## 11.1 Visual Studio Solution

The solution should be located approximately at:

```text
C:\local\src\ACE\ACE_vs2022.sln
```

Open the solution in Visual Studio.

Retarget it to the Visual Studio version installed on your machine.

Use:

```text
Configuration: Release
Platform:      x64
```

---

## 11.2 VS 2026 Compatibility Patches

If required by your Visual Studio version, create:

```text
C:\local\src\ACE\ace\config.h
```

with:

```cpp
#include "ace/config-win32.h"
```

Some newer Visual Studio versions may also require changes to:

```text
ace\Singleton.h
ace\Singleton.inl
ace\Singleton.cpp
```

The required compatibility changes involve adding `noexcept` to the relevant destructor, move-constructor, and move-assignment declarations/definitions.

> **Important:** These patches are compiler compatibility changes. If the upstream ACE source changes, verify whether they are still necessary before applying them blindly.

---

## 11.3 Build ACE

Build the complete solution using:

```text
Release | x64
```

ACE contains a large number of projects, so the build can take considerably longer than the Turtle-WoW source itself.

After the build completes, verify that the required ACE libraries and DLLs exist.

---

## 11.4 Set `ACE_ROOT`

Create the system environment variable:

```text
ACE_ROOT=C:\local\src\ACE
```

Restart any command prompts or Visual Studio instances that were open before changing the environment variables.

---

# 12. Obtaining the Turtle-WoW Source

Clone the source repository:

```bash
git clone https://github.com/Penqle/tortoise-wow.git F:\Servers\turtlewow\tortoise-wow-main
```

The source should now be located at:

```text
F:\Servers\turtlewow\tortoise-wow-main
```

## Record the Source Revision

For reproducibility, record the commit that you successfully built:

```bash
cd F:\Servers\turtlewow\tortoise-wow-main
git rev-parse HEAD
```

Save the resulting commit hash somewhere in your server documentation.

> **Why?** Git repositories change over time. A guide that says only "clone the repository" may produce different results months later.

---

# 13. Configuring CMake

The source needs to know where the external dependencies were installed.

Depending on the source revision, relevant variables may include:

```text
OPENSSL_ROOT_DIR
ZLIB_ROOT
SDL2_DIR
RECAST_ROOT
ACE_ROOT
```

Check:

```text
CMakeLists.txt
```

and:

```text
cmake/FindACE.cmake
```

for the exact variables expected by the source revision you are using.

Update them to match your directory layout.

For example:

```text
OPENSSL_ROOT_DIR = C:\local\openssl-1.1.1s
ZLIB_ROOT        = C:\local\zlib
SDL2_DIR         = C:\local\SDL
RECAST_ROOT      = C:\local\recast-1.6.0
ACE_ROOT         = C:\local\src\ACE
```

> **Tip:** Do not assume these paths are identical for every source revision. Always check the project's CMake files.

---

# 14. Client Build Compatibility

The source used by this guide expects client build:

```text
7207
```

Locate:

```text
src/server/realmlist.cpp
```

Find:

```cpp
static RealmBuildInfo ExpectedRealmdClientBuilds[] =
```

The relevant client build value should be changed from:

```text
7199
```

to:

```text
7207
```

This makes the server expect the client version used by the Turtle-WoW setup described in this guide.

> **Important:** The client and server must use compatible builds. If the server expects a different client build, the client may be rejected during login.

---

# 15. Configuring System PATH

Add the required runtime directories to PATH.

For the example directory layout:

```text
C:\local\openssl-1.1.1s\bin
C:\local\zlib\bin
C:\local\SDL\bin
C:\local\recast-1.6.0\Release
C:\local\src\ACE\bin\Release
```

You can either add these globally to the Windows PATH or create a developer-specific environment.

> **Recommendation:** A developer-specific PATH is preferable if you do not want these libraries available system-wide.

Restart Command Prompt/PowerShell after changing PATH.

---

# 16. Building the MaNGOS Server

Create a separate build directory:

```text
F:\Servers\turtlewow\tortoise-wow-build
```

Keeping the build directory separate from the source directory makes it easier to clean and rebuild the project.

---

## 16.1 Generate the Visual Studio Solution

Open CMake GUI.

Set:

```text
Source:
F:\Servers\turtlewow\tortoise-wow-main

Build:
F:\Servers\turtlewow\tortoise-wow-build
```

Configure the project for the installed Visual Studio version and x64.

Generate the Visual Studio solution.

> **Important:** In this guide CMake is being used primarily to **generate the Visual Studio build system**. Visual Studio performs the actual compilation.

---

## 16.2 Open Visual Studio

Open the generated solution.

Select:

```text
Configuration: Release
Platform:      x64
```

Perform:

```text
Build → Clean Solution
```

Then:

```text
Build → Build Solution
```

---

## 16.3 Verify the Build

After a successful build, the server binaries should be located approximately at:

```text
F:\Servers\turtlewow\tortoise-wow-build\bin\Release
```

Look for:

```text
mangosd.exe
realmd.exe
```

Required runtime DLLs should also be available.

If `ACE.dll` is not already present, copy the required ACE DLL from the ACE build output into:

```text
F:\Servers\turtlewow\tortoise-wow-build\bin\Release
```

---

# 17. Installing Server Patches

Download the required server patch archive:

https://www.mediafire.com/file/bpqqxrglydurpmq/patches.rar

Extract the contents into:

```text
F:\Servers\turtlewow\tortoise-wow-build\bin\Release\patches
```

Create the directory if it does not already exist.

The resulting structure should resemble:

```text
bin\
└── Release\
    ├── mangosd.exe
    ├── realmd.exe
    ├── ACE.dll
    └── patches\
        └── ...
```

> **Important:** Server patches and client patches are not necessarily the same thing. Keep them organized separately.

---

# 18. Setting Up MySQL

Install MySQL 8.0:

https://dev.mysql.com/downloads/mysql/

Start the MySQL service.

Create a dedicated MySQL account for the server rather than using the root account for normal operation.

For example:

```text
Username: mangos
Password: <strong password>
```

Use a strong password appropriate for your environment.

---

## 18.1 Create the Databases

The source tree provides SQL files for creating the required databases.

Import the database creation script:

```cmd
mysql -u mangos -p < F:\Servers\turtlewow\tortoise-wow-main\sql\create_databases.sql
```

Enter the password when prompted.

---

## 18.2 Import Base Data

The exact SQL layout can change between source revisions.

If the source uses the `sql\base` directory, import the required world data according to the project's SQL structure.

For example:

```cmd
for %%f in (F:\Servers\turtlewow\tortoise-wow-main\sql\base\*.sql) do (
    mysql -u mangos -p world < "%%f"
)
```

> **Note:** The exact import syntax depends on the SQL files and the database structure provided by your source revision. Check the repository's SQL documentation if it differs from this example.

---

## 18.3 Database Updates

The first successful server startup may apply pending database updates automatically, depending on the source revision and configuration.

Watch the `mangosd` console for database update messages.

Do not interrupt database updates unless you have a specific reason to stop the server.

---

# 19. Configuring the Client

Locate the WoW client's:

```text
realmlist.wtf
```

Edit it so that it points to your server.

For a server running on the same PC:

```text
set realmlist 127.0.0.1
```

For another computer on the LAN, use the server computer's LAN address instead:

```text
set realmlist 192.168.1.100
```

Replace the example address with the actual server's LAN address.

---

## 19.1 Install Client Patches

If the server-provided patches are also required by the client, copy them into the client's:

```text
Data
```

directory.

For example:

```text
F:\Servers\turtlewow\TurtleWoW Client\Data
```

Do **not** place them into:

```text
Data\patches
```

unless the particular patch documentation explicitly says to do so.

The expected layout depends on the client and patch files.

---

# 20. First Server Startup

The recommended startup order is:

```text
1. MySQL
2. realmd.exe
3. mangosd.exe
4. WoW client
```

---

## 20.1 Start MySQL

Confirm that the MySQL service is running.

---

## 20.2 Start `realmd.exe`

Open Command Prompt in:

```text
F:\Servers\turtlewow\tortoise-wow-build\bin\Release
```

Run:

```cmd
realmd.exe
```

Keep the console open.

If it immediately closes or reports an error, start it from Command Prompt rather than double-clicking it so that the error remains visible.

---

## 20.3 Start `mangosd.exe`

Open another Command Prompt in the same directory:

```cmd
mangosd.exe
```

Allow the server to finish loading.

The initial startup may take significantly longer than subsequent startups because the server may need to process database updates or initialize data.

---

## 20.4 Start the Client

Launch:

```text
WoW.exe
```

The client should connect to the address specified in:

```text
realmlist.wtf
```

For a same-PC server:

```text
127.0.0.1
```

---

# 21. LAN Setup

A local server can be run entirely inside your home network.

## 21.1 Same Computer

Use:

```text
127.0.0.1
```

The traffic never needs to leave the computer.

```text
WoW Client
    │
    ▼
127.0.0.1
    │
    ▼
realmd / mangosd
```

---

## 21.2 Another Computer on the LAN

The client computer needs to connect to the server computer's LAN IP.

For example:

```text
Server:
192.168.1.100

Client realmlist:
set realmlist 192.168.1.100
```

Find the server's address with:

```cmd
ipconfig
```

Look for the active network adapter's IPv4 address.

---

## 21.3 Windows Firewall

If another LAN computer cannot connect, check Windows Firewall.

You may need to allow the server executable or the required server ports through the firewall.

> For a LAN-only server, there is normally no reason to expose the server directly to the Internet.

---

# 22. Server Configuration

The server's configuration files control many runtime settings.

Typical configuration files include:

```text
realmd.conf
mangosd.conf
```

The exact filenames and locations depend on the source revision.

---

## Configuration vs. Source Changes

It is important to understand the difference.

### Configuration Change

Example:

```text
Change XP rate
      ↓
Edit configuration
      ↓
Restart server
```

No recompilation is normally required.

### Source Code Change

Example:

```text
Change C++ code
      ↓
Modify source
      ↓
Run CMake if necessary
      ↓
Build with Visual Studio
      ↓
Replace binaries
      ↓
Restart server
```

Understanding this distinction prevents unnecessary rebuilds.

---

# 23. Server Administration

Once the server works, administration becomes more important than installation.

## Starting

Recommended order:

```text
MySQL
 ↓
realmd
 ↓
mangosd
 ↓
WoW client
```

## Stopping

Close the server processes using their normal shutdown mechanism rather than forcibly terminating them whenever possible.

This gives the server an opportunity to save state and close database connections cleanly.

---

## Logs

When troubleshooting, always look at:

* `realmd` console
* `mangosd` console
* server log files
* MySQL errors
* client error messages

The first error in the log is often more useful than the final error.

---

# 24. Database Backups

Your database contains important persistent data.

At minimum, back up:

* character data
* account data
* custom SQL
* configuration files

A typical MySQL backup uses:

```cmd
mysqldump -u mangos -p <database> > backup.sql
```

For multiple databases, create separate backups or use a database list appropriate for your installation.

Store backups somewhere outside the live server directory.

For example:

```text
Backups\
├── database\
├── config\
├── patches\
└── source\
```

> **Recommendation:** Make a backup before applying major SQL updates or experimental modifications.

---

# 25. Customization

Once the server is working, there are several ways to customize it.

## 25.1 Configuration

Use configuration files for settings exposed by the server.

Examples can include:

* XP rates
* loot rates
* spawn settings
* gameplay settings
* network settings

---

## 25.2 SQL

SQL can be used to modify database-backed content.

Depending on the project, this can include:

* NPCs
* items
* quests
* vendors
* spawns
* game data

Always keep custom SQL separate from the original project SQL.

For example:

```text
custom-sql\
├── npcs.sql
├── vendors.sql
├── quests.sql
└── spawns.sql
```

This makes your changes easier to back up and reproduce.

---

## 25.3 Source Code

Changes to the C++ source require rebuilding the server.

A good workflow is:

```text
Make change
    ↓
Build
    ↓
Test
    ↓
Check logs
    ↓
Keep/revert change
```

Keep your changes under version control whenever possible.

---

# 26. Updating the Server

Updating a source-based server involves more than downloading new files.

Potentially affected components include:

* Turtle-WoW source
* third-party dependencies
* database schema
* world database
* server patches
* client compatibility

Before updating:

1. Back up the databases.
2. Back up configuration files.
3. Record the current Git commit.
4. Record custom source changes.
5. Record custom SQL.
6. Keep a copy of the currently working binaries.

Then update one component at a time.

> **Important:** Do not assume that the latest source automatically works with the exact client and dependencies used by this guide.

---

# 27. Troubleshooting

# CMake Problems

## `Could NOT find ACE`

Check:

```text
ACE_ROOT
```

Verify:

```cmd
echo %ACE_ROOT%
```

It should point to:

```text
C:\local\src\ACE
```

Also check that the ACE libraries were actually built.

---

## OpenSSL Cannot Be Found

Check:

```text
OPENSSL_ROOT_DIR
```

and verify that the expected directories exist:

```text
include
lib
bin
```

Also check whether you are accidentally mixing x86 and x64 libraries.

---

# Visual Studio Problems

## Missing `.lib` Files

This usually means that:

* a dependency was not built
* the wrong architecture was built
* CMake is pointing to the wrong directory
* Visual Studio is using the wrong configuration

Check that everything is consistently:

```text
Release
x64
```

---

## ACE Will Not Compile

Check:

* Visual Studio version
* ACE version
* required compatibility patches
* x64 configuration

Do not immediately replace ACE with a newer version.

The source may depend on the specific ACE API expected by the project.

---

# Runtime DLL Problems

## `ACE.dll` Missing

If Windows reports that `ACE.dll` is missing:

1. Verify that ACE was built.
2. Find the resulting DLL.
3. Copy it into the server's `bin\Release` directory, or
4. Add its directory to PATH.

For this guide, keeping required runtime DLLs beside the server executable is often the simplest option.

---

# MySQL Problems

## Access Denied

Verify:

* username
* password
* hostname
* database permissions

Test the account manually:

```cmd
mysql -u mangos -p
```

---

## Database Does Not Exist

Inside MySQL:

```sql
SHOW DATABASES;
```

Verify that the expected databases were created.

---

# `realmd.exe` Problems

If `realmd.exe` immediately closes:

Do not launch it by double-clicking.

Instead:

```cmd
cd F:\Servers\turtlewow\tortoise-wow-build\bin\Release
realmd.exe
```

Read the error displayed in the console.

Common causes include:

* database connection failure
* missing DLL
* incorrect configuration
* missing realm database
* incompatible binaries

---

# `mangosd.exe` Problems

If `mangosd.exe` fails during startup, check the console output first.

Potential causes include:

* MySQL connection failure
* missing world data
* incorrect configuration
* missing DLL
* incompatible database revision
* incorrect server patch files

---

# Client Cannot Connect

Check the following in order:

```text
Is MySQL running?
       ↓
Is realmd running?
       ↓
Is mangosd running?
       ↓
Is realmlist.wtf correct?
       ↓
Is the client build correct?
       ↓
Are the required client patches installed?
       ↓
Is Windows Firewall blocking the connection?
```

For a same-PC installation, verify:

```text
set realmlist 127.0.0.1
```

For a LAN installation, verify that the client uses the server's LAN IP.

---

# Client Build Rejected

Verify the source code's expected client build.

This guide uses:

```text
7207
```

Check:

```text
src/server/realmlist.cpp
```

and confirm that the expected build matches the client you are using.

---

# Patches Not Loading

Verify whether the patch is intended for:

* the server
* the client
* both

Server patches belong under:

```text
bin\Release\patches
```

Client data patches belong in the appropriate client `Data` directory.

Do not assume that a directory named `patches` should be created inside `Data`.

---

# 28. Frequently Asked Questions

## Can I use a different drive?

Yes.

The paths in this guide are examples.

For example, you can use:

```text
D:\Servers\turtlewow
```

instead of:

```text
F:\Servers\turtlewow
```

Update your CMake configuration and commands accordingly.

---

## Can I use Visual Studio Community?

If the required C++ development tools are available, a Community edition may be sufficient for a personal/development installation.

The important part is having the required MSVC compiler, Windows SDK, and C++ tooling.

---

## Do I need port forwarding?

Not for a server used only on the same computer or local network.

Port forwarding is only relevant if you intentionally want clients from outside your LAN to connect.

---

## Can multiple people play?

A LAN deployment can be used by multiple computers, provided that:

* the server can handle the player count
* clients can reach the server
* Windows Firewall allows the required traffic
* clients use compatible versions
* the server is configured correctly

---

## Do I need to rebuild the server after changing configuration?

Normally, no.

Changes to `.conf` files generally require only a server restart.

Changes to C++ source require recompilation.

---

## Can I use newer dependencies?

Possibly, but do not assume compatibility.

C++ projects can depend on specific APIs, library layouts, compiler behavior, and ABI compatibility.

When troubleshooting a build, first reproduce the documented versions before experimenting with newer ones.

---

# 29. Known Limitations

This guide intentionally targets a specific environment.

The following can change over time:

* Turtle-WoW source code
* Git repository structure
* SQL structure
* dependency versions
* Visual Studio compatibility
* client compatibility
* patch files
* CMake configuration

Therefore, this guide should be considered a **versioned build recipe**, not a guarantee that every future source revision will build using exactly the same instructions.

When updating the server, record the versions and Git commit you used.

---

# 30. Quick-Start Checklist

## Windows

* [ ] Windows x64 installed
* [ ] Visual Studio installed
* [ ] Desktop development with C++ installed
* [ ] CMake installed
* [ ] Git installed
* [ ] MySQL installed

## Dependencies

* [ ] OpenSSL installed/built
* [ ] zlib installed
* [ ] SDL2 installed
* [ ] Recast/Detour built
* [ ] ACE 8.0.5 built
* [ ] `ACE_ROOT` configured
* [ ] PATH configured

## Source

* [ ] Turtle-WoW repository cloned
* [ ] Source commit recorded
* [ ] Client build changed to `7207`
* [ ] CMake paths configured

## Build

* [ ] CMake generated Visual Studio solution
* [ ] Release selected
* [ ] x64 selected
* [ ] Solution built successfully
* [ ] `mangosd.exe` exists
* [ ] `realmd.exe` exists
* [ ] Required DLLs exist

## Server Patches

* [ ] Server `patches` directory created
* [ ] Server patch files installed
* [ ] Client patch/data files installed where required

## Database

* [ ] MySQL service running
* [ ] `mangos` database account created
* [ ] Databases created
* [ ] Base SQL imported
* [ ] Database updates completed

## Client

* [ ] Correct client installed
* [ ] Client build matches server
* [ ] `realmlist.wtf` configured
* [ ] Client patches installed

## Startup

* [ ] MySQL started
* [ ] `realmd.exe` started
* [ ] `mangosd.exe` started
* [ ] Client launched
* [ ] Client connected successfully

---

# 31. Glossary

### ACE

**Adaptive Communication Environment.**

A C++ framework used by the server source.

### CMake

A build-system generator that creates project files for systems such as Visual Studio.

### Client Build

A numeric identifier representing a particular version of the WoW client.

This guide uses:

```text
7207
```

### DLL

**Dynamic-Link Library.**

A Windows library that can be loaded by an executable at runtime.

### MaNGOS

An open-source MMORPG server framework on which various World of Warcraft server projects are based.

### `mangosd`

The world/game server executable.

### MySQL

The database server used to store persistent server information.

### Realm

A game-world/server instance presented to the client.

### `realmd`

The login/authentication and realm server executable.

### `realmlist.wtf`

A client configuration file specifying which server address the WoW client should contact.

### Recast/Detour

Libraries used for navigation mesh generation and pathfinding.

### SQL

**Structured Query Language.**

Used to create, query, and modify the server's database.

---

# 32. Final Reference

The basic workflow can be summarized as:

```text
┌─────────────────────┐
│ Install Windows     │
│ development tools   │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Build dependencies  │
│ ACE / OpenSSL /     │
│ Recast / etc.       │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Obtain Turtle-WoW   │
│ source              │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Configure CMake     │
│ and client build    │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Build with          │
│ Visual Studio       │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Install server      │
│ patches              │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Configure MySQL     │
│ and import SQL      │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Configure client    │
│ realmlist.wtf       │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Start MySQL         │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Start realmd        │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Start mangosd       │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Start WoW client    │
└──────────┬──────────┘
           ↓
       Connected!
```

Once the server is working, keep a record of your **source commit, dependency versions, client build, configuration files, patches, and database backups**. That information makes future rebuilds and troubleshooting substantially easier.
