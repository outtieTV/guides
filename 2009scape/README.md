# 2009scape LAN Server Guide

**A guide to setting up a 2009scape RuneScape private server for LAN play with family and friends**

> **Guide scope:** This guide focuses on running 2009scape on a **local network (LAN)**. It does not require port forwarding or exposing the server to the public Internet.

---

## Table of Contents

* [About This Guide](#about-this-guide)
* [How the Server Works](#how-the-server-works)
* [Server vs. Client PCs](#server-vs-client-pcs)
* [Requirements](#requirements)
* [Network Setup](#network-setup)
* [Preparing Windows](#preparing-windows)
* [Installing the 2009scape Server](#installing-the-2009scape-server)
* [Configuring the Server](#configuring-the-server)
* [Setting Up the Database](#setting-up-the-database)
* [Building the Server](#building-the-server)
* [Building the Saradomin Client](#building-the-saradomin-client)
* [Connecting to the Server](#connecting-to-the-server)
* [Adding Additional Players](#adding-additional-players)
* [Testing the Installation](#testing-the-installation)
* [Server Configuration](#server-configuration)
* [Troubleshooting](#troubleshooting)
* [Backups and Maintenance](#backups-and-maintenance)
* [LAN vs. Internet Hosting](#lan-vs-internet-hosting)
* [Glossary](#glossary)
* [Useful Resources](#useful-resources)

---

# About This Guide

Other 2009scape server guides I found tended to focus on hosting a server over the Internet, including port forwarding and other networking configuration.

This guide is intended for a simpler use case:

> **You want to run a 2009scape server at home and let computers on your local network connect to it.**

The goal is to get a working server running on one Windows PC and allow other computers on the same network to connect using the server PC's local IP address.

## What This Guide Covers

* Installing the required software on Windows
* Installing and configuring the 2009scape server
* Setting up MySQL
* Importing the 2009scape database
* Compiling the server
* Compiling the Saradomin client
* Configuring the client for LAN connections
* Allowing multiple computers to connect
* Testing the connection
* Basic troubleshooting
* Basic maintenance and backups

## What This Guide Does Not Cover

This guide does **not** focus on:

* Port forwarding
* Hosting a publicly accessible server
* Dynamic DNS
* VPS hosting
* Public server security
* Internet-facing MySQL
* Domain names

Those are separate topics and are unnecessary for a basic LAN installation.

---

# How the Server Works

Before installing anything, it helps to understand what the different components are doing.

A basic LAN installation looks approximately like this:

```text
                         Home LAN
                            │
             ┌──────────────┴──────────────┐
             │                             │
        Server PC                      Client PC(s)
             │                             │
     ┌───────┴───────┐              Saradomin Client
     │               │
2009scape Server    MySQL
     │
     └───────────────┘
```

### 2009scape Server

The server is responsible for running the game world.

It handles things such as:

* Players
* NPCs
* Combat
* Movement
* Items
* World state
* Accounts
* Game logic

### MySQL

MySQL stores persistent information used by the server.

For example, player/account information can be stored in the database so it remains available after the server is restarted.

### Saradomin

Saradomin is the client used to connect to the 2009scape server.

The client needs to know the IP address of the computer running the server.

### Java

The 2009scape server requires Java to compile and run.

### Visual Studio

Visual Studio is used to compile the C# Saradomin client.

### HeidiSQL

HeidiSQL is a graphical database management program. It is not the database itself; it simply makes working with MySQL easier.

---

# Server vs. Client PCs

Throughout this guide, the following terms are used:

### Server PC

The computer running:

* 2009scape Server
* MySQL
* The server configuration

### Client PC

A computer running the Saradomin game client.

The server PC can also run the client if you want to play on the same computer that hosts the server.

For example:

```text
Server PC
192.168.1.50
│
├── 2009scape Server
├── MySQL
└── Saradomin Client
       │
       └── Player 1

Client PC
192.168.1.51
│
└── Saradomin Client
       │
       └── Player 2

Client PC
192.168.1.52
│
└── Saradomin Client
       │
       └── Player 3
```

All clients would connect to:

```text
192.168.1.50
```

because that is the IP address of the **server PC**.

---

# Requirements

## Server PC

The following software is used by this guide:

| Software      | Version / Requirement | Purpose                          |
| ------------- | --------------------- | -------------------------------- |
| Windows       | Windows 10/11         | Operating system                 |
| Java JDK      | JDK 11                | Server runtime/build environment |
| MySQL         | 5.7                   | Database                         |
| HeidiSQL      | Current version       | Database management              |
| Visual Studio | 2022                  | Building the client              |
| 2009scape     | `master` branch       | Server                           |
| Saradomin     | `master` branch       | Client                           |
| Glitonea      | Commit `9fb6de8`      | Client dependency                |

> **Important:** This guide uses specific dependency versions because older projects may not work correctly with newer versions. Do not assume that installing the newest available version of every dependency will work.

## Recommended but Optional Tools

The following are useful for troubleshooting but aren't necessarily required to run the server:

* Windows Telnet Client
* Ping/ICMP access
* A text editor
* A database backup solution

---

# Network Setup

For LAN play, all computers need to be connected to the same local network.

For example:

```text
Router
  │
  ├── Server PC
  │     192.168.1.50
  │
  ├── Client PC
  │     192.168.1.51
  │
  └── Client PC
        192.168.1.52
```

The exact addresses on your network may be different.

Common private IP address ranges include:

```text
192.168.x.x
10.x.x.x
172.16.x.x - 172.31.x.x
```

## Find the Server's LAN IP

On the server PC, open Command Prompt and run:

```cmd
ipconfig
```

Look for the network adapter you are using and find its IPv4 address.

For example:

```text
IPv4 Address. . . . . . . . . . . : 192.168.1.50
```

This is the address other computers will use to connect to the server.

## Static IP vs. DHCP Reservation

The server should ideally keep the same LAN IP address.

There are two common ways to accomplish this.

### Option 1: Configure a Static IP in Windows

Windows can be configured with a fixed IP address.

### Option 2: Create a DHCP Reservation

Many routers can be configured to always assign the same IP address to the server PC.

A DHCP reservation is often easier to maintain because Windows can continue using automatic IP configuration while the router consistently gives the server the same address.

Either approach can work.

---

# Preparing Windows

## 1. Install Java JDK 11

Download and install Java JDK 11 from BellSoft:

https://bell-sw.com/pages/downloads/#jdk-11-lts

This guide uses the BellSoft Liberica JDK 11 distribution.

After installation, open **Command Prompt as Administrator** and set `JAVA_HOME`.

For example:

```cmd
setx -m JAVA_HOME "C:\Program Files\BellSoft\LibericaJDK-11"
```

> **Note:** Your installation directory may be different depending on the JDK version and installation options.

After running `setx`, open a **new** Command Prompt.

You can verify the Java installation with:

```cmd
java -version
```

You can also check `JAVA_HOME` with:

```cmd
echo %JAVA_HOME%
```

---

## 2. Install MySQL 5.7

Download and install MySQL Server and Client 5.7:

[MySQL 5.7 Downloads](https://dev.mysql.com/downloads/windows/installer/5.7.html)

For this guide, configure MySQL to use:

```text
Port:     3306
Username: root
Password: none
```

> **Security note:** A root account without a password is not recommended for an Internet-facing database. This setup is intended for a private LAN installation. Do not expose MySQL port `3306` to the Internet.

---

## 3. Install HeidiSQL

Download and install HeidiSQL:

https://www.heidisql.com/

HeidiSQL provides a graphical interface for managing the MySQL database.

You will use it later to import the 2009scape database.

---

## 4. Verify MySQL Is Running

Press the Windows key and search for:

```text
Services
```

Open the Windows Services application.

Find the MySQL service and make sure it is running.

You can also start/stop/restart MySQL from this window.

---

## 5. Enable Windows Ping

Allow ICMP echo requests through Windows Firewall if you want to use `ping` to test LAN connectivity.

This is useful for troubleshooting, but **ping is not required for 2009scape itself**.

A guide for enabling ping through Windows Firewall:

[Allow Ping Through Windows Firewall](https://www.thewindowsclub.com/how-to-allow-pings-icmp-echo-requests-through-windows-firewall)

After enabling it, another computer can test the server with:

```cmd
ping 192.168.1.50
```

Replace the example IP with your server's actual LAN IP.

---

## 6. Install the Windows Telnet Client

Open:

**Control Panel → Programs → Turn Windows features on or off**

Enable:

```text
Telnet Client
```

Telnet is useful for testing whether a specific TCP port can be reached.

For example:

```cmd
telnet 192.168.1.50 43595
```

> **Note:** Telnet is being used here as a basic connectivity test. You do not need to use Telnet to actually play the game.

---

## 7. Show File Extensions

Open File Explorer.

Go to:

**View → Show → File name extensions**

Alternatively, open File Explorer Options and disable:

> Hide extensions for known file types

This makes it easier to distinguish files such as:

```text
run-server.bat
run-server.bat.txt
```

which can otherwise be confusing when troubleshooting.

---

## 8. Install Visual Studio 2022

Download Visual Studio Community:

[Visual Studio Community](https://visualstudio.microsoft.com/vs/community/)

Install the components required for C# development.

The client will be compiled later using Visual Studio.

---

# Installing the 2009scape Server

## 1. Download 2009scape

Download the 2009scape source:

[2009scape GitLab](https://gitlab.com/2009scape/2009scape)

You can download the repository as a ZIP archive.

This guide uses:

```text
master
```

> **Important:** The `master` branch can change over time. If a future version of 2009scape changes its dependencies or build process, some steps in this guide may need to be updated.

---

## 2. Create the Server Directory

Create:

```text
C:\2009scape
```

Extract the server source into this directory.

The resulting directory should look approximately like:

```text
C:\2009scape\
├── Server\
├── ...
├── run-server.bat
└── ...
```

---

# Configuring the Server

The main configuration file used in this guide is:

```text
C:\2009scape\Server\Worldprops\default.conf
```

Open the file in a text editor.

A basic configuration can look like:

```ini
[server]
use_auth = true
persist_accounts = true
noauth_default_admin = true
watchdog_enabled = false

[world]
debug = false
dev = false
start_gui = false
daily_restart = true
```

## What These Settings Do

| Setting                | Purpose                                                                 |
| ---------------------- | ----------------------------------------------------------------------- |
| `use_auth`             | Controls server authentication                                          |
| `persist_accounts`     | Controls whether account information persists                           |
| `noauth_default_admin` | Controls default administrator behavior when authentication is disabled |
| `watchdog_enabled`     | Controls the server watchdog                                            |
| `debug`                | Enables additional debugging output                                     |
| `dev`                  | Enables development functionality                                       |
| `start_gui`            | Controls whether the server GUI starts                                  |
| `daily_restart`        | Controls automatic daily restarting                                     |

> **Recommendation:** Start with the default configuration whenever possible. Only change settings when you know what behavior you want to change.

There may be additional settings in the configuration file that are not covered by this guide.

---

# Setting Up the Database

The 2009scape server uses MySQL for persistent data.

## 1. Start MySQL

Open:

```text
Services
```

and make sure the MySQL server is running.

---

## 2. Open HeidiSQL

Launch HeidiSQL.

Create a connection using:

```text
Host:     127.0.0.1
Port:     3306
User:     root
Password: [blank]
```

Connect to the server.

> **Note:** `127.0.0.1` means "this computer." Since MySQL is running on the same computer as the 2009scape server, you can use localhost for this connection.

---

## 3. Import the 2009scape Database

In HeidiSQL, select:

**File → Load SQL file**

Open:

```text
C:\2009scape\Server\db_exports\global.sql
```

Execute the SQL file.

This creates/imports the database structure and data required by the server.

After the import completes, verify that the database/tables are visible in HeidiSQL.

---

# Building the Server

Once Java, MySQL, and the source code are ready, the server can be built.

Navigate to:

```text
C:\2009scape
```

Run:

```text
run-server.bat
```

The first build may take a while.

Allow the build process to complete.

If the server starts successfully, keep the server window running while testing the client.

> **Important:** The server needs to remain running while players are connected. Closing the server process will disconnect players and stop the game world.

---

# Windows Firewall

When Windows asks whether Java should be allowed through the firewall, allow it as appropriate for your network.

For a LAN-only installation, the important thing is that the server is reachable by computers on your local network.

If the client cannot connect later, Windows Firewall should be one of the first things you check.

---

# Building the Saradomin Client

The server and client are separate pieces of software.

The client needs to be configured with the address of your server.

---

## 1. Download Saradomin

Download the Saradomin Launcher source:

[Saradomin Launcher on GitLab](https://gitlab.com/2009scape/Saradomin-Launcher)

This guide originally used the launcher because the official client compilation process was problematic at the time. The official client now compiles successfully, so the launcher/client instructions may change as the project evolves.

---

## 2. Create the Client Directory

Create:

```text
C:\2009scapeLauncher
```

Extract the Saradomin source so that the solution exists at:

```text
C:\2009scapeLauncher\Saradomin.sln
```

---

# Installing Glitonea

Download Glitonea at commit:

```text
9fb6de8
```

Source:

[Glitonea commit 9fb6de8](https://github.com/vddCore/Glitonea/tree/9fb6de8da53dbdde9d782ce4ab1c36c61d98ff71)

Create:

```text
C:\2009scapeLauncher\Glitonea
```

Extract Glitonea so that the project file is located at:

```text
C:\2009scapeLauncher\Glitonea\Glitonea.csproj
```

The directory should look approximately like:

```text
C:\2009scapeLauncher\
├── Saradomin.sln
├── Saradomin\
└── Glitonea\
    └── Glitonea.csproj
```

---

# Configure the Client

Open:

```text
C:\2009scapeLauncher\Saradomin.sln
```

with Visual Studio 2022.

Change the build configuration from:

```text
Debug
```

to:

```text
Release
```

---

## Locate ClientSettings.cs

In Solution Explorer, navigate to:

```text
Solution 'Saradomin'
└── Saradomin
    └── Model
        └── Settings
            └── Client
                └── ClientSettings.cs
```

Open:

```text
ClientSettings.cs
```

---

# Configure the Server Address

The client contains server profiles that determine where it connects.

Remove server profiles that you do not intend to use.

Keep:

```text
TestServerAddress
LocalServerAddress
```

For a LAN server, configure:

```text
TestServerAddress
```

to point to the server PC's **LAN IP address**.

For example:

```text
TestServerAddress = "192.168.1.50"
```

Replace `192.168.1.50` with the actual IP address of your server PC.

> **Important:** The address should be the IP of the **server PC**, not the client PC.

---

# LocalServerAddress vs. TestServerAddress

These addresses serve different purposes.

## LocalServerAddress

Use this when the client and server are running on the **same computer**.

For example:

```text
127.0.0.1
```

or:

```text
localhost
```

## TestServerAddress

Use this when the client needs to connect to the server over your LAN.

For example:

```text
192.168.1.50
```

A second computer on the network should use the server's LAN address rather than `localhost`.

---

# External Connections

If you later decide to allow players outside your LAN to connect, the configuration will be different.

The client would need to connect to your public IP address or domain name, and your router/firewall would need to allow the appropriate traffic.

That is **outside the scope of this LAN guide**.

Do not expose services such as MySQL to the Internet simply to make the game client work.

---

# Build the Client

Save:

```text
Ctrl + S
```

Then press the green:

**Start Without Debugging**

button in Visual Studio.

The client should build and launch.

If the build succeeds, the compiled files will be located in the Release output directory.

---

# Getting In-Game

If you accidentally close the launcher, you can manually start it again.

The compiled client should be located under:

```text
C:\2009scapeLauncher\Saradomin\bin\Release\net6.0\
```

Run:

```text
Saradomin.exe
```

---

## Configure Saradomin

Open the client settings.

Enter the location of your Java executable:

```text
java.exe
```

Select:

```text
Server Profile: Testing Server
```

Then press:

```text
Play
```

If everything is configured correctly, you should be able to connect to your server.

Create an account and enter the game.

---

# Adding Additional Players

Once the server is working, additional players on the same LAN can connect to it.

The additional computers need:

* The Saradomin client
* The appropriate client dependencies
* A network connection to the server PC

They do **not** need their own copy of MySQL.

They do **not** need to run the 2009scape server.

They only need the client.

For example:

```text
Server PC
192.168.1.50
│
├── 2009scape Server
└── MySQL
      ▲
      │
      │ LAN
      │
      ├──────── Client PC 1
      │          192.168.1.51
      │
      ├──────── Client PC 2
      │          192.168.1.52
      │
      └──────── Client PC 3
                 192.168.1.53
```

Each client should configure its server address as:

```text
192.168.1.50
```

assuming that is the server PC's LAN IP.

---

# Testing the Installation

If the client cannot connect, test the system one layer at a time.

---

## Test 1: Check the Server IP

On the server PC:

```cmd
ipconfig
```

Confirm that the IP address hasn't changed.

---

## Test 2: Ping the Server

From another PC:

```cmd
ping 192.168.1.50
```

If ping fails, check:

* Both computers are on the same network
* The server PC is online
* The IP address is correct
* Windows Firewall
* Wi-Fi client/AP isolation

> **Note:** A failed ping does not automatically mean the game server is unreachable. ICMP can be blocked independently of TCP connections.

---

## Test 3: Test Port 43595

From another computer:

```cmd
telnet 192.168.1.50 43595
```

If the connection succeeds, the TCP port is reachable.

If it fails, check:

* The 2009scape server is running
* The server is listening on the expected port
* Windows Firewall
* The server configuration
* The IP address

---

## Test 4: Check the Server Console

Look at the server console for errors or connection attempts.

If the client is attempting to connect but immediately disconnects, the server output may provide additional information.

---

## Test 5: Check the Client Configuration

Make sure:

```text
TestServerAddress
```

contains the server PC's LAN IP.

For example:

```text
"192.168.1.50"
```

Do not use:

```text
127.0.0.1
```

unless the client and server are running on the same PC.

---

# Troubleshooting

## Java Is Not Recognized

Try:

```cmd
java -version
```

If Windows cannot find Java, check:

```cmd
echo %JAVA_HOME%
```

Make sure `JAVA_HOME` points to the JDK installation.

After changing environment variables, open a new Command Prompt.

---

## MySQL Will Not Connect

Check the Windows Services application.

Make sure the MySQL service is running.

Verify:

```text
Host: 127.0.0.1
Port: 3306
Username: root
Password: blank
```

---

## The SQL Import Fails

Make sure you are importing the SQL file supplied with the same 2009scape server source you are using:

```text
C:\2009scape\Server\db_exports\global.sql
```

Mixing database files from different versions of the project may cause compatibility problems.

---

## The Client Cannot Connect

Check the following in order:

1. Is the 2009scape server running?
2. Is the client using the server PC's LAN IP?
3. Can the client PC ping the server?
4. Can the client PC reach TCP port `43595`?
5. Is Windows Firewall blocking Java/the server?
6. Has the server's IP address changed?
7. Are the computers actually on the same LAN?

---

## `localhost` Works but the LAN IP Does Not

If the client works on the server PC using:

```text
127.0.0.1
```

but another computer cannot connect, the problem is likely related to networking or firewall configuration rather than the basic server installation.

Check:

```cmd
ipconfig
```

on the server.

Then test from the other PC:

```cmd
ping SERVER_IP
```

and:

```cmd
telnet SERVER_IP 43595
```

---

## Another Computer Cannot Ping the Server

Check:

* Windows Firewall
* Network profile
* Wi-Fi isolation/client isolation
* Whether both machines are connected to the same router/network
* Whether the server's IP address is correct

Some guest Wi-Fi networks prevent devices from communicating with one another.

---

# Backups and Maintenance

Once your server is working, it is worth thinking about maintenance.

Your server contains information that you may not want to lose, particularly player/account data.

## Database Backups

The MySQL database should be backed up periodically.

A database backup allows you to recover player information if:

* MySQL becomes corrupted
* You accidentally modify data
* A server update causes problems
* Windows fails
* You need to move the server to another PC

HeidiSQL can also be used to export database information.

## Configuration Backups

Keep backups of important configuration files, including:

```text
C:\2009scape\Server\Worldprops\
```

If you make custom changes to the server, keep a copy of those changes separately from the main source tree when possible.

---

# Updating the Server

Because this guide uses the `master` branch, the project may change after this guide was written.

Before updating:

1. Stop the server.
2. Back up the database.
3. Back up your configuration files.
4. Record any custom modifications.
5. Update the source code.
6. Check the project's current documentation for dependency changes.
7. Rebuild the server.
8. Check for database changes.
9. Start the server.
10. Test with a client before allowing other players to connect.

> **Important:** Do not assume that replacing the source code is always sufficient for an update. Database schemas, dependencies, configuration files, and client/server compatibility can change between versions.

---

# LAN vs. Internet Hosting

This guide intentionally uses a LAN configuration.

## LAN Hosting

Players connect using a private address such as:

```text
192.168.1.50
```

Advantages:

* No port forwarding
* No public IP required
* No domain required
* Server isn't directly exposed to the Internet
* Simple setup for people in the same home/network

## Internet Hosting

Internet hosting requires additional considerations, including:

* Public IP address
* Router configuration
* Port forwarding
* Firewall configuration
* Potential dynamic IP changes
* Server security
* Account/security considerations
* Potential DDoS or abuse concerns

If your goal is simply to play with people in your home, **LAN hosting avoids much of this additional complexity.**

---

# Glossary

### Client

The program players use to connect to the game server.

### Server

The program responsible for running the game world.

### LAN

**Local Area Network.**

The private network connecting computers in your home or local environment.

### IP Address

An address used to identify a computer on a network.

Example:

```text
192.168.1.50
```

### localhost

The current computer.

Usually represented by:

```text
127.0.0.1
```

### Port

A numbered network endpoint used by applications to communicate.

The game server uses a game connection port such as:

```text
43595
```

### JDK

**Java Development Kit.**

Contains the Java tools needed to build and run Java applications.

### MySQL

The database server used to store persistent game data.

### SQL

A language used to create, read, modify, and manage database data.

### HeidiSQL

A graphical program used to manage databases such as MySQL.

### Saradomin

The client used to connect to 2009scape.

---

# Useful Resources

## 2009scape

[2009scape GitLab](https://gitlab.com/2009scape/2009scape)

## Saradomin Launcher

[Saradomin Launcher GitLab](https://gitlab.com/2009scape/Saradomin-Launcher)

## Glitonea

[Glitonea on GitHub](https://github.com/vddCore/Glitonea)

## Java JDK 11

[BellSoft Liberica JDK](https://bell-sw.com/pages/downloads/#jdk-11-lts)

## MySQL 5.7

[MySQL Downloads](https://dev.mysql.com/downloads/windows/installer/5.7.html)

## HeidiSQL

[HeidiSQL](https://www.heidisql.com/)

## Visual Studio

[Visual Studio Community](https://visualstudio.microsoft.com/vs/community/)

---

# Final Checklist

Before considering the installation complete, verify:

* [ ] Java JDK 11 is installed
* [ ] `JAVA_HOME` is configured
* [ ] MySQL 5.7 is installed
* [ ] MySQL is running on port `3306`
* [ ] HeidiSQL can connect to MySQL
* [ ] `global.sql` has been imported
* [ ] 2009scape has been extracted to `C:\2009scape`
* [ ] `default.conf` has been configured
* [ ] `run-server.bat` successfully starts the server
* [ ] Windows Firewall allows the required traffic
* [ ] The server PC has a known/stable LAN IP
* [ ] Saradomin has been compiled successfully
* [ ] `TestServerAddress` points to the server PC
* [ ] The client can connect to the server
* [ ] An account can be created
* [ ] A second computer can connect over the LAN

---

# Congratulations!

You now have a 2009scape server running on your local network.

The server PC hosts the game world and database, while other computers on the LAN can connect using the server PC's private IP address.

From here, you can begin exploring server configuration, administration, customization, backups, and other aspects of running your own 2009scape server.
