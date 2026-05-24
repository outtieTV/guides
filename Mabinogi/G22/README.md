## Mabinogi G22 Server & Client Setup Guide

> **All file paths are relative to the root folder where you extracted the G22 package.**  
> Adjust any paths if you placed the files elsewhere.

---  

### 1️⃣ Download & Extract

1. Download the **server** and **client** archives.  
2. Extract both archives to the same root folder (e.g., `C:\MabinogiG22`).  
   The folder structure should look like:

```
C:\MabinogiG22\
│   install.bat
│   ServerInfo.ini
│   …
├─ RCSWork\Client\
│   install.bat
│   Client.exe
│   …
├─ RCSWork\Server\
│   install.bat
│   Server.exe
│   …
└─ NpcClient_ch1\
    ClientD.exe
    NPCAccount.xml
    NPCClient.xml
    …
```

---  

### 2️⃣ Fix Shortcut Paths  

Edit all shortcut (`*.lnk`) files so they point to the **actual** locations of the executables you just extracted.  
Typical corrections:

| Shortcut | Desired Target |
|----------|----------------|
| Server | `C:\MabinogiG22\RCSWork\Server\Server.exe` |
| Client | `C:\MabinogiG22\RCSWork\Client\Client.exe` |
| NPC client | `C:\MabinogiG22\NpcClient_ch1\ClientD.exe` |

---  

### 3️⃣ Run Installation Batch Files  

| Location | Action |
|----------|--------|
| `RCSWork\Client` | Open `install.bat` and let it finish. |
| `RCSWork\Server` | Open `install.bat` and let it finish. |

These scripts copy required libraries and set up the working directories.

---  

### 4️⃣ Configure the Server  

1. **Port** – Open `loginserver\ServerInfo.ini` and set:

```ini
port = 21000
```

2. **Server name** – In **every** `.ini` file, replace:

```ini
SERVER_NAME = CH1
```

with

```ini
SERVER_NAME = sqlq
```

---  

### 5️⃣ Set Up NPC Account  

1. Edit `NpcClient_ch1\NPCAccount.xml` and `NpcClient_ch1\NPCClient.xml`.  
   Replace the placeholder values with your desired credentials, for example:

```xml
<username>xxx123</username>
<password>123123</password>
```

2. **Password hashing** – Passwords are stored as **MD5 uppercase** strings.  
   If you need to reset the password, use **xmldbaccountmanager** and **uncheck the SHA‑256 box**.

---  

### 6️⃣ Launch the Server Stack  

Run the server executables **in this order** (each in a separate console window):

1. `loginserver.exe`  
2. `worldserver.exe`  
3. `otherserver.exe` (if present)  

Make sure each process stays running before starting the next.

---  

### 7️⃣ Start the NPC Client  

Create a `start.bat` inside `NpcClient_ch1` with the following contents:

```bat
cd NpcClient_ch1
start ClientD.exe code:1215 logip:127.0.0.1 logport:21000 render:no setting:"file://data/features.xml=Regular, China" npcbatchjob:default sublocale:ServerGroup09
```

Run this batch file **after** the server stack is up.

---  

### 8️⃣ Log in with the NPC Account  

1. Launch the **NPC client** (`ClientD.exe`).  
2. Log in using the NPC credentials you defined in step 5.  

> **Correction:** Log in **after** the client starts, then enter the commands below.

#### NPC Commands

```text
>move /r:15 /x:1000 /y:1000
>set_condition /a:23
```

Wait until the command log shows “process commands end” before proceeding.

---  

### 9️⃣ Start the Normal Client  

Create a `start.bat` in the client root folder (`RCSWork\Client` or wherever `Client.exe` lives) with:

```bat
start Client.exe code:1622 ver:200 logip:127.0.0.1 logport:21000 setting:"file://data/features.xml=Regular, China"
```

Run this batch file to launch the game client and connect to your local server.

---  

### 🔧 Additional Notes  

* **Multiplayer DLL** – If you encounter multiplayer issues, replace `DINPUT8.dll` with the version from the **G20** release.  
* **Database connection strings** – Use **dnSpy** on `xmldb.exe` and `xmldb.dll` to view the embedded connection strings (e.g., database name, user, password).  
* **MD5 hashing** – To generate the required uppercase MD5 hash for a password, you can use any online MD5 tool and then convert the result to uppercase, e.g.:

```
password → md5 → 5F4DCC3B5AA765D61D8327DEB882CF99 → store exactly as shown
```

---  

### ✅ Quick Checklist

- [ ] Shortcuts point to correct executable locations.  
- [ ] `install.bat` run for both client and server.  
- [ ] `ServerInfo.ini` port set to **21000**.  
- [ ] All `.ini` files use `SERVER_NAME = sqlq`.  
- [ ] NPC XML files contain your chosen username/password (MD5‑hashed).  
- [ ] SHA‑256 disabled in `xmldbaccountmanager` if resetting passwords.  
- [ ] Server binaries launched in the proper order.  
- [ ] NPC client started, logged in, and commands executed.  
- [ ] Normal client started with `start.bat`.  

You should now be able to run a local Mabinogi G22 server with both the NPC client and the regular client connected. Happy testing!
