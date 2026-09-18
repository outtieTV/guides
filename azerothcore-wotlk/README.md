# AzerothCore WotLK + Playerbot Guide

## Ubuntu 26.04 LTS

This guide covers installing and configuring an **AzerothCore WotLK server with Playerbot support on Ubuntu 26.04 LTS**.

The goal is to provide both a quick installation path and enough explanation that you understand what each component does and how to troubleshoot it later.

---

# Table of Contents

* [1. What This Guide Installs](#1-what-this-guide-installs)
* [2. Requirements](#2-requirements)
* [3. How AzerothCore Works](#3-how-azerothcore-works)
* [4. Quick Start](#4-quick-start)
* [5. Install Build Dependencies](#5-install-build-dependencies)
* [6. Download AzerothCore](#6-download-azerothcore)
* [7. Install Modules](#7-install-modules)
* [8. Patch jemalloc](#8-patch-jemalloc)
* [9. Build AzerothCore](#9-build-azerothcore)
* [10. Extract Client Data](#10-extract-client-data)
* [11. Configure MySQL](#11-configure-mysql)
* [12. Configure AzerothCore](#12-configure-azerothcore)
* [13. Create the AzerothCore Databases](#13-create-the-azerothcore-databases)
* [14. Configure the Realm Address](#14-configure-the-realm-address)
* [15. Start the Servers](#15-start-the-servers)
* [16. Create a Player Account](#16-create-a-player-account)
* [17. Create an Admin Account](#17-create-an-admin-account)
* [18. Configure Playerbot](#18-configure-playerbot)
* [19. Configure AuctionBot](#19-configure-auctionbot)
* [20. LAN vs Internet Servers](#20-lan-vs-internet-servers)
* [21. Firewall Configuration](#21-firewall-configuration)
* [22. Client Configuration](#22-client-configuration)
* [23. Verify the Installation](#23-verify-the-installation)
* [24. Using `screen`](#24-using-screen)
* [25. systemd Services](#25-systemd-services)
* [26. Backing Up the Server](#26-backing-up-the-server)
* [27. Updating AzerothCore](#27-updating-azerothcore)
* [28. Troubleshooting](#28-troubleshooting)
* [29. Performance Considerations](#29-performance-considerations)
* [30. Security Notes](#30-security-notes)
* [31. Useful Commands](#31-useful-commands)
* [32. Final Checklist](#32-final-checklist)

---

# 1. What This Guide Installs

By the end of this guide you will have:

* AzerothCore WotLK
* The `Playerbot` branch of the mod-playerbots fork
* MySQL
* Authentication database
* Characters database
* World database
* Extracted client data
* Optional AzerothCore modules
* Playerbot support
* Optional AuctionBot configuration
* A GM/admin account
* A client configured to connect to your server

The server can be configured for:

* **LAN-only play**
* **Internet-accessible play**
* **VPN/mesh-network play**

This guide focuses on running the server on Ubuntu rather than setting up a dedicated website, account-registration system, custom launcher, or custom WoW client.

---

# 2. Requirements

## Operating System

This guide assumes:

* Ubuntu 26.04 LTS
* 64-bit installation
* A user account with `sudo` access

Check your Ubuntu version with:

```bash
lsb_release -a
```

You can also check the kernel:

```bash
uname -a
```

---

## Hardware

AzerothCore itself is not particularly demanding, but **Playerbot can significantly increase CPU and RAM usage** depending on the number of bots.

As a general starting point:

| Component                | Suggested             |
| ------------------------ | --------------------- |
| CPU                      | 4+ cores              |
| RAM                      | 8 GB minimum          |
| RAM with many Playerbots | 16 GB+ recommended    |
| Storage                  | 30+ GB free           |
| Network                  | LAN, VPN, or Internet |

The actual requirements depend heavily on the number of players, bots, and enabled modules.

---

## Software Knowledge

Basic familiarity with the following is useful:

* Linux terminal commands
* `sudo`
* `nano`
* Git
* MySQL
* IP addresses
* Basic networking

You do not need to be an expert in C++ or Linux administration to follow the guide.

---

# 3. How AzerothCore Works

AzerothCore is made up of several components.

```text
                    WoW Client
                         |
                         |
                    TCP Port 3724
                         |
                         v
                  +--------------+
                  | Auth Server   |
                  +--------------+
                         |
                         |
                    MySQL Auth DB
                         |
                         v
                  +--------------+
                  | World Server  |
                  +--------------+
                         |
                    TCP Port 8085
                         |
                         v
                    WoW Client
```

The MySQL server contains three important databases:

```text
acore_auth
acore_characters
acore_world
```

### Auth Server

The authentication server handles logging into the server.

It uses the `acore_auth` database.

### World Server

The world server runs the actual game world.

It handles:

* Maps
* NPCs
* Quests
* Characters
* Combat
* Playerbots
* Modules

It uses the `acore_world` and `acore_characters` databases.

### Playerbot

Playerbot allows computer-controlled characters to participate in the game.

Playerbot is part of the `mod-playerbots` project used by this guide.

### AHBot

AHBot is separate from Playerbot.

```text
Playerbot
    |
    +-- Computer-controlled player characters

AHBot
    |
    +-- Automatically populated Auction House
```

You can use Playerbot without necessarily using AHBot.

---

# 4. Quick Start

If you already understand Linux, MySQL, AzerothCore, and networking, the basic process is:

```text
1. Install dependencies
2. Clone AzerothCore
3. Download modules
4. Initialize submodules
5. Patch jemalloc if required
6. Build AzerothCore
7. Extract client data
8. Configure MySQL
9. Configure AzerothCore
10. Initialize databases
11. Configure realm address
12. Enable modules
13. Start authserver
14. Start worldserver
15. Create an account
16. Configure realmlist.wtf
17. Connect with the WoW client
```

The rest of this guide explains each step.

---

# 5. Install Build Dependencies

Update Ubuntu's package lists:

```bash
sudo apt-get update
```

Install the required build and runtime dependencies:

```bash
sudo apt-get install -y \
    build-essential cmake git pkg-config \
    g++ clang libstdc++-16-dev libc++-dev \
    libboost-all-dev libssl-dev libcrypto++-dev \
    libmysql++-dev default-libmysqlclient-dev mysql-server \
    zlib1g-dev libbz2-dev libreadline-dev \
    libjemalloc-dev libgoogle-perftools-dev \
    libtool automake libpthread-stubs0-dev libncurses-dev libedit-dev \
    protobuf-compiler libprotobuf-dev \
    liblua5.1-0-dev lua5.1 \
    libevent-dev \
    clang-tidy clang-format
```

## What are these packages for?

The packages can generally be grouped into several categories.

### Build tools

```text
build-essential
cmake
git
pkg-config
```

These provide the compiler, build system, source-control tools, and dependency discovery tools.

### C/C++ libraries

```text
Boost
OpenSSL
Crypto++
zlib
bzip2
jemalloc
```

These provide libraries used by AzerothCore and its dependencies.

### MySQL

```text
mysql-server
default-libmysqlclient-dev
libmysql++-dev
```

These provide the database server and MySQL development libraries.

### Lua / Protobuf

These provide additional libraries required by the core and/or modules.

---

## Verify the compiler

```bash
g++ --version
```

Verify CMake:

```bash
cmake --version
```

Verify Git:

```bash
git --version
```

Verify MySQL:

```bash
mysql --version
```

If these commands return version information, continue.

---

# 6. Download AzerothCore

Move to your home directory:

```bash
cd ~
```

Clone the Playerbot fork:

```bash
git clone https://github.com/mod-playerbots/azerothcore-wotlk.git \
    --branch=Playerbot
```

Enter the directory:

```bash
cd ~/azerothcore-wotlk
```

Verify the branch:

```bash
git branch --show-current
```

You should see:

```text
Playerbot
```

You can also record the exact commit being used:

```bash
git rev-parse --short HEAD
```

This is useful when troubleshooting because AzerothCore and its modules are actively developed.

---

# 7. Install Modules

AzerothCore modules are stored under:

```text
~/azerothcore-wotlk/modules
```

Enter the modules directory:

```bash
cd ~/azerothcore-wotlk/modules
```

Download the module helper script:

```bash
wget https://raw.githubusercontent.com/outtieTV/guides/main/azerothcore-wotlk/get-modules.sh
```

Make it executable:

```bash
chmod +x get-modules.sh
```

Run it:

```bash
bash get-modules.sh
```

You can inspect the downloaded script before running it:

```bash
head -n 20 get-modules.sh
```

> **Note:** Only run scripts you trust. If you are following this guide in the future, check the repository to make sure the script has not changed.

---

## Initialize Git submodules

Return to the AzerothCore directory:

```bash
cd ~/azerothcore-wotlk
```

Initialize all submodules:

```bash
git submodule update --init --recursive
```

This ensures that dependencies stored as Git submodules are available.

---

# 8. Patch jemalloc

The current build may require a small change to jemalloc.

Navigate to the source:

```bash
cd ~/azerothcore-wotlk/deps/jemalloc/src
```

Open the file:

```bash
nano jemalloc_cpp.cpp
```

Find:

```cpp
std::__throw_bad_alloc();
```

Replace it with:

```cpp
std::bad_alloc();
```

Save the file:

```text
Ctrl+O
Enter
Ctrl+X
```

You can verify the change with:

```bash
grep -n "bad_alloc" jemalloc_cpp.cpp
```

> **Important:** This is a workaround for the current source/dependency combination. If a future AzerothCore update no longer contains the problematic code, do not blindly apply this modification.

---

# 9. Build AzerothCore

Return to the project directory:

```bash
cd ~/azerothcore-wotlk
```

Compile the servers:

```bash
./acore.sh compiler all
```

This builds the authentication and world servers.

The first compilation can take some time.

---

## Verify the build

After compilation completes:

```bash
ls -lh ~/azerothcore-wotlk/env/dist/bin/
```

You should see the generated server executables.

If the build fails, do not immediately continue to the database setup. See the [Troubleshooting](#28-troubleshooting) section and inspect the build error.

---

# 10. Extract Client Data

AzerothCore requires data extracted from a compatible WotLK client.

From the AzerothCore directory:

```bash
cd ~/azerothcore-wotlk
```

Run:

```bash
./acore.sh client-data
```

Follow the prompts.

The extracted data is used by the world server for things such as:

* Maps
* DBC files
* Game data
* Movement information
* VMaps
* MMaps

> **Important:** The server does not provide the WoW client itself. You need a compatible WotLK client separately.

---

# 11. Configure MySQL

AzerothCore stores server data in MySQL.

The installation creates three main databases:

```text
acore_auth
acore_characters
acore_world
```

---

## 11.1 Check MySQL

Check the service:

```bash
sudo systemctl status mysql
```

Or:

```bash
systemctl is-active mysql
```

Expected:

```text
active
```

If it is not running:

```bash
sudo systemctl start mysql
```

Enable it at boot:

```bash
sudo systemctl enable mysql
```

---

# 12. Configure `secure-file-priv`

Create the MySQL secure file directory:

```bash
sudo mkdir -p /var/lib/mysql-files
```

Set its owner:

```bash
sudo chown mysql:mysql /var/lib/mysql-files
```

Set its permissions:

```bash
sudo chmod 750 /var/lib/mysql-files
```

Check MySQL's configuration:

```bash
grep -i secure-file-priv /etc/mysql/mysql.conf.d/mysqld.cnf
```

The expected configuration is:

```text
secure-file-priv = /var/lib/mysql-files
```

Restart MySQL:

```bash
sudo systemctl daemon-reload
sudo systemctl restart mysql.service
```

Verify:

```bash
sudo systemctl status mysql.service
```

It should report:

```text
active (running)
```

---

# 13. Create the `acore` MySQL User

Open MySQL:

```bash
sudo mysql -u root
```

Create the AzerothCore database user:

```sql
DROP USER IF EXISTS 'acore'@'localhost';
DROP USER IF EXISTS 'acore'@'127.0.0.1';

CREATE USER 'acore'@'localhost'
    IDENTIFIED BY '<SECUREPASSWORD>';

CREATE USER 'acore'@'127.0.0.1'
    IDENTIFIED BY '<SECUREPASSWORD>';

GRANT ALL PRIVILEGES ON *.*
    TO 'acore'@'localhost'
    WITH GRANT OPTION;

GRANT ALL PRIVILEGES ON *.*
    TO 'acore'@'127.0.0.1'
    WITH GRANT OPTION;

FLUSH PRIVILEGES;
```

Exit MySQL:

```sql
exit;
```

Replace:

```text
<SECUREPASSWORD>
```

with a strong password.

### Why create both users?

MySQL treats:

```text
acore@localhost
```

and:

```text
acore@127.0.0.1
```

as separate accounts.

AzerothCore configuration can use either connection form, so creating both avoids authentication surprises.

---

# 14. Run MySQL's Security Script

Run:

```bash
sudo mysql_secure_installation
```

Follow the prompts.

This can be used to remove unnecessary/default MySQL configuration and improve the security of the database server.

---

# 15. Configure AzerothCore

AzerothCore's generated configuration files are located under:

```text
~/azerothcore-wotlk/env/dist/etc
```

Enter the directory:

```bash
cd ~/azerothcore-wotlk/env/dist/etc
```

---

## Set the MySQL password

The following command replaces the default `acore` password in the generated configuration files.

Replace `<strongpassword>` with the password you chose earlier:

```bash
find . -type f -name '*.conf' ! -name '*.conf.dist' \
    -exec grep -Iq . {} \; -print0 |
    xargs -0 sed -i -E \
    's/(127\.0\.0\.1;3306;acore;)(acore)/\1<strongpassword>/g'
```

Check the resulting configuration:

```bash
grep -R "127.0.0.1;3306;acore" .
```

Make sure the password is correct.

> **Security:** Configuration files containing database passwords should not be shared publicly.

---

# 16. Create the AzerothCore Databases

AzerothCore can initialize its databases when the server is first started.

---

## 16.1 Initialize the Auth Database

Run:

```bash
cd ~/azerothcore-wotlk
./acore.sh run-authserver
```

When prompted to create the databases, answer:

```text
y
```

Allow the database initialization to complete.

Then stop the server with:

```text
Ctrl+C
```

---

# 17. Configure the Realm Address

The realm address tells clients where they should connect to the world server.

First determine your LAN address:

```bash
ip addr show
```

You can also use:

```bash
ifconfig -a
```

If `ifconfig` is not installed:

```bash
sudo apt install net-tools -y
```

A typical LAN address looks like:

```text
192.168.1.100
```

---

## Set the realm address

Replace `<LAN IP>` with your server's LAN address:

```bash
mysql -u acore -p<SECUREPASSWORD> \
    -e "UPDATE acore_auth.realmlist SET address = '<LAN IP>';"
```

For example:

```bash
mysql -u acore -pMyPassword \
    -e "UPDATE acore_auth.realmlist SET address = '192.168.1.100';"
```

> Do not put a space between `-p` and the password in this particular command.

---

# 18. Initialize the World and Characters Databases

Start the world server:

```bash
cd ~/azerothcore-wotlk
./acore.sh run-worldserver
```

The first startup can take some time while the databases are populated and updated.

Watch the console for database update activity.

Once the server has finished starting, you can stop it with:

```text
.server exit
```

This allows the world server to shut down cleanly.

---

# 19. Create a Player Account

You can create accounts from the worldserver console.

Start the world server:

```bash
cd ~/azerothcore-wotlk
./acore.sh run-worldserver
```

Then use:

```text
account create player <PASSWORD>
```

For example:

```text
account create player MyPassword123
```

The username is:

```text
player
```

The password is:

```text
MyPassword123
```

You can now use this account from the WoW client.

---

# 20. Create an Admin Account

It is recommended to keep your normal player account separate from your GM account.

From the worldserver console:

```text
account create admin <ADMIN_PASSWORD>
```

Then give it GM level 3:

```text
account set gmlevel admin 3 -1
```

GM level 3 provides high-level administrative access.

> Avoid using your GM account as your normal gameplay account. Keeping administrative and normal accounts separate reduces the chance of accidentally modifying the server while playing.

---

# 21. Configure Playerbot

Playerbot is one of the main reasons for using the `mod-playerbots` branch.

Module configuration files are located under:

```text
~/azerothcore-wotlk/env/dist/etc/modules
```

List the available module configurations:

```bash
ls ~/azerothcore-wotlk/env/dist/etc/modules
```

Open the relevant Playerbot configuration:

```bash
nano ~/azerothcore-wotlk/env/dist/etc/modules/<PLAYERBOT-CONFIG>
```

Enable the module by changing its appropriate setting from:

```text
Enable = 0
```

to:

```text
Enable = 1
```

The exact configuration names can vary as the Playerbot project develops, so use the configuration file included with the version you built.

---

## Playerbot performance

Playerbots require additional CPU and memory.

As the number of bots increases, server resource usage can also increase.

If the server becomes slow:

1. Reduce the number of active bots.
2. Check CPU usage.
3. Check RAM usage.
4. Check the worldserver logs.
5. Disable unnecessary modules.
6. Reduce bot-related configuration limits.

---

# 22. Enable Other Modules

AzerothCore modules are generally configured under:

```text
~/azerothcore-wotlk/env/dist/etc/modules
```

Edit the module configuration:

```bash
nano ~/azerothcore-wotlk/env/dist/etc/modules/<MODULE>.conf
```

If the module provides an enable setting:

```text
Enable = 0
```

change it to:

```text
Enable = 1
```

Some modules require additional configuration or database updates.

Always read the module's documentation before enabling it.

---

# 23. Configure AuctionBot

AuctionBot is optional.

It can be used to populate the Auction House with automatically generated listings.

The exact configuration depends on the AHBot module version included in your build.

---

## 23.1 Create the AuctionBot account

Open MySQL:

```bash
mysql -u acore -p
```

Select the auth database:

```sql
USE acore_auth;
```

Create the account:

```sql
INSERT INTO account (
    username,
    salt,
    verifier,
    session_key,
    totp_secret,
    email,
    reg_mail,
    expansion
) VALUES (
    'AuctionBot',
    UNHEX('00...00'),
    UNHEX('00...00'),
    NULL,
    NULL,
    'auctionbot@example.com',
    'auctionbot@example.com',
    2
);
```

> The exact account schema can change between AzerothCore revisions. If this SQL no longer matches your `account` table, inspect the current table definition with `DESCRIBE account;` and follow the database schema for the version you built.

Get the account ID:

```sql
SELECT id AS account_id
FROM account
WHERE username = 'AuctionBot';
```

Write down the returned `account_id`.

---

# 24. Create the AuctionBot Character

Select the characters database:

```sql
USE acore_characters;
```

Find a candidate GUID:

```sql
SELECT IFNULL(MAX(guid),0) + 1 AS next_guid
FROM characters;
```

Suppose this returns:

```text
1001
```

and your AuctionBot account ID is:

```text
102
```

You can create the character:

```sql
INSERT INTO characters (
    guid,
    account,
    name,
    race,
    class,
    gender,
    level,
    xp,
    money,
    skin,
    face,
    hairStyle,
    hairColor,
    facialStyle,
    bankSlots,
    restState,
    playerFlags,
    position_x,
    position_y,
    position_z,
    map,
    instance_id,
    taximask,
    innTriggerId
) VALUES (
    1001,
    102,
    'SellBuyBot',
    1,
    1,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    -8949.95,
    -132.50,
    83.53,
    0,
    0,
    0,
    0
);
```

---

## Important note about GUIDs

The example:

```sql
MAX(guid) + 1
```

is a convenient manual method for a small/private server.

It should not be treated as a general-purpose GUID allocation system for a busy server where multiple characters could be created concurrently.

For a personal server, it is generally sufficient when performed carefully.

---

# 25. Configure AHBot

Open the AHBot configuration:

```bash
nano ~/azerothcore-wotlk/env/dist/etc/modules/mod-AHBot.conf
```

Set the appropriate bot account/character setting to the account ID created earlier.

For example:

```text
BotAccountId = 102
```

The exact setting name can vary between AHBot versions.

Search the file:

```bash
grep -i "account" ~/azerothcore-wotlk/env/dist/etc/modules/mod-AHBot.conf
```

Then verify the configuration against the version of the module you installed.

Restart the worldserver after changing module configuration.

---

# 26. LAN vs Internet Servers

There are three common ways to connect to your server.

## Option 1: LAN

This is the simplest and safest setup for playing with computers on the same network.

Example server address:

```text
192.168.1.100
```

Client:

```text
set realmlist 192.168.1.100
```

No router port forwarding is required.

---

## Option 2: Internet

For Internet access, the connection generally looks like:

```text
Internet
    |
    v
Router
    |
    | Port forwarding
    v
Ubuntu Server
    |
    +--> Auth Server :3724
    |
    +--> World Server :8085
```

You will need:

* A public IP address
* Router port forwarding
* Ubuntu firewall configuration
* Correct AzerothCore realm address
* Correct client `realmlist.wtf`

---

## Option 3: VPN / Mesh Network

A VPN or mesh VPN can allow remote players to connect without exposing the AzerothCore ports directly to the public Internet.

Examples include:

* Tailscale
* WireGuard
* Other private VPN solutions

In that case, clients use the VPN address of the server.

---

# 27. Firewall Configuration

If you are using UFW, first make sure SSH is allowed:

```bash
sudo ufw allow OpenSSH
```

Then allow the AzerothCore ports:

```bash
sudo ufw allow 3724/tcp
sudo ufw allow 8085/tcp
```

Enable UFW:

```bash
sudo ufw enable
```

Check the configuration:

```bash
sudo ufw status
```

You should see rules for:

```text
3724/tcp
8085/tcp
```

---

## Router port forwarding

For Internet access, forward:

```text
TCP 3724 -> Ubuntu server
TCP 8085 -> Ubuntu server
```

For example:

```text
Internet
   |
   | TCP 3724
   v
192.168.1.100:3724

Internet
   |
   | TCP 8085
   v
192.168.1.100:8085
```

The exact router interface varies by manufacturer.

> **Do not forward MySQL port 3306 to the Internet.** AzerothCore clients do not need direct access to MySQL.

---

# 28. Configure the WoW Client

Locate the client's:

```text
realmlist.wtf
```

Depending on the client installation, this may be located in the client directory or under:

```text
Data/
```

Open the file and set:

```text
set realmlist <SERVER_IP>
```

For a LAN server:

```text
set realmlist 192.168.1.100
```

For an Internet server:

```text
set realmlist <YOUR_PUBLIC_IP>
```

For a VPN server:

```text
set realmlist <YOUR_VPN_IP>
```

---

## Launch the client

Launch:

```text
WoW.exe
```

directly rather than using the Blizzard launcher.

Log in using your account credentials.

For example:

```text
Username: player
Password: <PASSWORD>
```

---

# 29. Verify the Installation

Before troubleshooting, verify each component independently.

## MySQL

```bash
systemctl is-active mysql
```

Expected:

```text
active
```

---

## Authserver

Start:

```bash
cd ~/azerothcore-wotlk
./acore.sh run-authserver
```

Verify that it starts without database connection errors.

---

## Worldserver

Start:

```bash
cd ~/azerothcore-wotlk
./acore.sh run-worldserver
```

Wait for database loading and startup to complete.

---

## Check listening ports

Use:

```bash
sudo ss -lntp
```

Look for:

```text
3724
8085
```

You can filter it:

```bash
sudo ss -lntp | grep -E '3724|8085'
```

---

## Test the local connection

From the Ubuntu server:

```bash
sudo ss -lntp | grep 3724
sudo ss -lntp | grep 8085
```

If the services are listening, the next step is testing connectivity from the client.

---

# 30. Using `screen`

For a simple server that you start manually, `screen` is convenient.

Install it:

```bash
sudo apt install screen -y
```

---

## Auth server

Create a screen session:

```bash
screen -S authserver
```

Run:

```bash
cd ~/azerothcore-wotlk
./acore.sh run-authserver
```

Detach with:

```text
Ctrl+A
D
```

---

## World server

Create another session:

```bash
screen -S worldserver
```

Run:

```bash
cd ~/azerothcore-wotlk
./acore.sh run-worldserver
```

Detach:

```text
Ctrl+A
D
```

---

## List screen sessions

```bash
screen -ls
```

Example:

```text
There are screens on:
    1234.authserver
    5678.worldserver
```

---

## Reattach

```bash
screen -r authserver
```

or:

```bash
screen -r worldserver
```

---

# 31. systemd Services

`screen` is convenient for testing, but `systemd` is generally better for a server that should automatically start after reboot.

A typical setup uses:

```text
azerothcore-auth.service
azerothcore-world.service
```

The services can be configured to:

* Start at boot
* Restart if the process crashes
* Run without an interactive terminal
* Store logs in the system journal

After creating the services:

```bash
sudo systemctl daemon-reload
```

Enable them:

```bash
sudo systemctl enable azerothcore-auth
sudo systemctl enable azerothcore-world
```

Start them:

```bash
sudo systemctl start azerothcore-auth
sudo systemctl start azerothcore-world
```

Check status:

```bash
sudo systemctl status azerothcore-auth
sudo systemctl status azerothcore-world
```

Follow worldserver logs:

```bash
journalctl -u azerothcore-world -f
```

> A systemd setup is recommended for a long-running dedicated server, while `screen` is perfectly useful while learning, testing, or debugging.

---

# 32. Backing Up the Server

Once your server is working, **back it up before making major changes**.

---

## Back up the databases

```bash
mysqldump -u acore -p --all-databases \
    > ~/azerothcore-backup.sql
```

You can verify the file:

```bash
ls -lh ~/azerothcore-backup.sql
```

---

## Back up configuration

```bash
tar -czf ~/azerothcore-config-backup.tar.gz \
    ~/azerothcore-wotlk/env/dist/etc
```

---

## What should be backed up?

At minimum:

```text
MySQL databases
AzerothCore configuration
Module configuration
Custom SQL
Custom modules
Custom scripts
```

If you have custom server content, back that up as well.

---

# 33. Updating AzerothCore

AzerothCore and its modules change over time.

Before updating:

```bash
cd ~/azerothcore-wotlk
```

Check for uncommitted changes:

```bash
git status
```

Record your current commit:

```bash
git rev-parse --short HEAD
```

Back up the databases:

```bash
mysqldump -u acore -p --all-databases \
    > ~/azerothcore-before-update.sql
```

A typical update process is:

```text
Stop servers
      |
      v
Back up databases
      |
      v
Update source/modules
      |
      v
Update submodules
      |
      v
Rebuild
      |
      v
Run database updates
      |
      v
Start authserver
      |
      v
Start worldserver
      |
      v
Check logs
```

Do not assume that every future revision can be updated using the exact same Git commands. Check the current AzerothCore and Playerbot documentation when performing a major update.

---

# 34. Troubleshooting

## AzerothCore will not compile

Check:

```bash
g++ --version
cmake --version
```

Then inspect the first actual compiler error in the build output.

Do not focus only on the final:

```text
Build failed
```

message.

The useful error is usually earlier in the output.

---

## jemalloc error

Check whether the problematic symbol exists:

```bash
grep -n "__throw_bad_alloc" \
    ~/azerothcore-wotlk/deps/jemalloc/src/jemalloc_cpp.cpp
```

If it exists, verify that the source was changed according to the jemalloc section.

---

## MySQL will not start

Check:

```bash
sudo systemctl status mysql
```

Then:

```bash
sudo journalctl -u mysql --no-pager -n 100
```

Look for the first actual error.

---

## Authentication database connection fails

Check the AzerothCore configuration:

```bash
grep -R "127.0.0.1;3306;acore" \
    ~/azerothcore-wotlk/env/dist/etc
```

Verify:

* Username is `acore`
* Password is correct
* MySQL is running
* `acore@localhost` exists
* `acore@127.0.0.1` exists

You can test the credentials directly:

```bash
mysql -u acore -p
```

---

## Worldserver cannot find the database

Verify that the databases exist:

```bash
mysql -u acore -p -e "SHOW DATABASES;"
```

You should eventually see:

```text
acore_auth
acore_characters
acore_world
```

---

## Client cannot connect

Check the server:

```bash
sudo ss -lntp | grep -E '3724|8085'
```

Check UFW:

```bash
sudo ufw status
```

Check the client:

```text
realmlist.wtf
```

Make sure the address is correct.

---

## LAN works but Internet does not

This usually indicates a networking/NAT issue rather than an AzerothCore database issue.

Check:

```text
Public IP
    |
    v
Router
    |
    v
Port forwarding
    |
    v
Ubuntu LAN IP
    |
    v
UFW
    |
    v
AzerothCore
```

Verify that TCP ports:

```text
3724
8085
```

are forwarded to the correct Ubuntu machine.

---

## Auth works but entering the world fails

Check:

1. Worldserver is running.
2. Port 8085 is listening.
3. The realm address is correct.
4. The client can reach port 8085.
5. The world database finished loading.
6. The worldserver logs do not contain database errors.

---

## Playerbot is not working

Check:

```bash
ls ~/azerothcore-wotlk/env/dist/etc/modules
```

Verify that the Playerbot configuration exists.

Then check that the module is enabled.

Restart the worldserver after changing configuration.

Check the worldserver startup output for module loading messages.

---

## AHBot is not working

Verify:

* AHBot module is enabled.
* AuctionBot account exists.
* Account ID is correct.
* AuctionBot character exists.
* Character account ID matches the AuctionBot account.
* AHBot configuration references the correct account/character.
* Required database updates have been applied.

---

# 35. Performance Considerations

AzerothCore performance depends on:

* Number of players
* Number of Playerbots
* Number of active creatures
* Number of modules
* Database activity
* Server hardware

For a Playerbot server, monitor CPU and RAM:

```bash
top
```

or:

```bash
htop
```

If `htop` is not installed:

```bash
sudo apt install htop
```

Check RAM:

```bash
free -h
```

Check disk space:

```bash
df -h
```

If performance becomes poor, reduce the number of active bots before assuming the server itself is broken.

---

# 36. Security Notes

## Do not expose MySQL

Do not forward:

```text
3306
```

to the public Internet.

WoW clients should never need direct MySQL access.

---

## Protect your database password

The AzerothCore `.conf` files contain your database password.

Do not upload those configuration files publicly.

Be especially careful when posting:

```bash
cat *.conf
```

or screenshots of configuration files.

---

## Use separate accounts

A useful arrangement is:

```text
admin
    |
    +-- GM/admin account

player
    |
    +-- Normal gameplay account

AuctionBot
    |
    +-- AHBot account
```

This keeps administrative access separate from normal gameplay.

---

## LAN-only is simpler

If your server is only intended for friends or family on the same network, there is generally no need to expose the server to the public Internet.

Use the server's LAN IP:

```text
192.168.x.x
```

and do not configure router port forwarding.

---

# 37. Useful Commands

## Start authserver

```bash
cd ~/azerothcore-wotlk
./acore.sh run-authserver
```

## Start worldserver

```bash
cd ~/azerothcore-wotlk
./acore.sh run-worldserver
```

## Build

```bash
cd ~/azerothcore-wotlk
./acore.sh compiler all
```

## Extract client data

```bash
cd ~/azerothcore-wotlk
./acore.sh client-data
```

## Check MySQL

```bash
systemctl status mysql
```

## Check listening ports

```bash
sudo ss -lntp | grep -E '3724|8085'
```

## Check firewall

```bash
sudo ufw status
```

## Check memory

```bash
free -h
```

## Check CPU/processes

```bash
htop
```

## Check Git branch

```bash
cd ~/azerothcore-wotlk
git branch --show-current
```

## Check Git revision

```bash
git rev-parse --short HEAD
```

---

# 38. Final Checklist

Before considering the installation complete, verify:

```text
[ ] Ubuntu 26.04 is installed
[ ] Build dependencies are installed
[ ] AzerothCore Playerbot branch is cloned
[ ] Modules are installed
[ ] Git submodules are initialized
[ ] jemalloc workaround applied if required
[ ] AzerothCore compiled successfully
[ ] Client data extracted
[ ] MySQL is running
[ ] MySQL secure-file-priv is configured
[ ] acore MySQL user exists
[ ] AzerothCore configuration contains the correct password
[ ] acore_auth exists
[ ] acore_characters exists
[ ] acore_world exists
[ ] Realm address is configured
[ ] Worldserver starts successfully
[ ] Authserver starts successfully
[ ] Ports 3724 and 8085 are listening
[ ] Firewall allows required ports
[ ] Player account exists
[ ] Admin account exists
[ ] Playerbot is enabled
[ ] Optional modules are enabled/configured
[ ] AHBot is configured if desired
[ ] realmlist.wtf points to the server
[ ] WoW client can log in
[ ] Character can enter the world
[ ] Playerbots work
[ ] Backups have been created
```

---

# 🎉 Finished

You now have an AzerothCore WotLK server running on Ubuntu with Playerbot support.

The basic server components are:

```text
Auth Server
    |
    +-- Authentication
    |
    v
MySQL
    |
    +-- acore_auth
    +-- acore_characters
    +-- acore_world
    |
    v
World Server
    |
    +-- Playerbot
    +-- AHBot
    +-- Other Modules
```

For a simple LAN server, the minimum you'll normally need to keep running is:

```text
MySQL
Authserver
Worldserver
```

Players then configure their client with:

```text
set realmlist <SERVER_IP>
```

and connect using an account created on the server.
