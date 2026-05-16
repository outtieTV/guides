# azerothcore-wotlk-guide
## Ubuntu 26.04 – AzerothCore WotLK + Playerbot Setup  

---

### 1️⃣ Install Build & Runtime Dependencies  

```bash
sudo apt-get update
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

---

### 2️⃣ Clone the Core & Pull Modules  

```bash
cd ~
git clone https://github.com/mod-playerbots/azerothcore-wotlk.git \
    --branch=Playerbot
cd ~/azerothcore-wotlk/modules

# get‑modules.sh
wget https://github.com/outtieTV/azerothcore-wotlk-guide/blob/main/get-modules.sh
chmod +x get-modules.sh
bash get-modules.sh

# initialise sub‑modules
git submodule update --init --recursive
```  

---

### 3️⃣ Patch jemalloc (required for the current build)

```bash
cd ~/azerothcore-wotlk/deps/jemalloc/src
sudo nano jemalloc_cpp.cpp   # → find std::__throw_bad_alloc();
# replace with
std::bad_alloc();
# save (Ctrl‑O) and exit (Ctrl‑X)
```  

---

### 4️⃣ Build the Core  

```bash
cd ~/azerothcore-wotlk
./acore.sh compiler all      # compiles both auth‑ and world‑servers
```  

---

### 5️⃣ Import Client Extracted Data  

```bash
./acore.sh client-data
```  

---

## MySQL Configuration  

### 5️⃣ Create the `secure‑file‑priv` directory  

```bash
sudo mkdir -p /var/lib/mysql-files
sudo chown mysql:mysql /var/lib/mysql-files
sudo chmod 750 /var/lib/mysql-files
```  

Verify the path used by MySQL:

```bash
grep -i secure-file-priv /etc/mysql/mysql.conf.d/mysqld.cnf
# expected output: secure-file-priv = /var/lib/mysql-files
```  

Reload and restart MySQL:

```bash
sudo systemctl daemon-reload
sudo systemctl restart mysql.service
sudo systemctl status mysql.service   # should be active (running)
```  

### 6️⃣ Create the `acore` MySQL user  

```bash
sudo mysql -u root
DROP USER IF EXISTS 'acore'@'localhost';
DROP USER IF EXISTS 'acore'@'127.0.0.1';
CREATE USER 'acore'@'localhost' IDENTIFIED BY '<SECUREPASSWORD>';
CREATE USER 'acore'@'127.0.0.1' IDENTIFIED BY '<SECUREPASSWORD>';
GRANT ALL PRIVILEGES ON *.* TO 'acore'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'acore'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit;
```  

### 7️⃣ Run the MySQL security script  

```bash
sudo mysql_secure_installation
```  

---

## Configure AzerothCore  

```bash
cd ~/azerothcore-wotlk/env/dist/etc
```  

Replace `<strongpassword>` with the password you set for the `acore` MySQL user:

```bash
find . -type f -name '*.conf' ! -name '*.conf.dist' \
    -exec grep -Iq . {} \; -print0 |
    xargs -0 sed -i -E 's/(127\.0\.0\.1;3306;acore;)(acore)/\1<strongpassword>/g'
```  

---

## Populate the Databases  

### 8️⃣ Build the auth database  

```bash
cd ~/azerothcore-wotlk
./acore run-authserver
# when prompted, answer “y” to create the databases
# stop the server with Ctrl‑C
```  

### 9️⃣ Set your realm’s address  

```bash
sudo apt install net-tools -y
ifconfig -a            # shows your LAN IP
ip addr show           # shows the public IP (if needed)

# replace <LAN IP> with the address you want clients to use
mysql -u acore -p<SECUREPASSWORD> \
    -e "UPDATE acore_auth.realmlist SET address = '<LAN IP>';"
```  

### 🔟 Build the world & characters databases  

```bash
cd ~/azerothcore-wotlk
./acore.sh run-worldserver
# wait until the databases finish loading
# exit the server console with: .server exit
```  

---

## AuctionBot (Playerbot) Account & Character  

### 11️⃣ Create the bot account  

```sql
-- inside mysql (mysql -u acore -p)
USE acore_auth;

INSERT INTO account (
    username, salt, verifier, session_key, totp_secret,
    email, reg_mail, expansion
) VALUES (
    'AuctionBot',
    UNHEX('00...00'),                       -- 32‑byte zeroed salt
    UNHEX('00...00'),                       -- 16‑byte zeroed verifier
    NULL, NULL,
    'auctionbot@example.com', 'auctionbot@example.com',
    2                                       -- WotLK expansion
);
```  

Get the newly created **account_id**:

```sql
SELECT id AS account_id FROM account WHERE username = 'AuctionBot';
```  

### 12️⃣ Create the bot character  

```sql
USE acore_characters;

-- get a free GUID
SELECT IFNULL(MAX(guid),0) + 1 AS next_guid FROM characters;
```

Assume the result is **1001** and the account_id from step 11 is **102**:

```sql
INSERT INTO characters (
    guid, account, name, race, class, gender, level, xp, money,
    skin, face, hairStyle, hairColor, facialStyle,
    bankSlots, restState, playerFlags,
    position_x, position_y, position_z, map,
    instance_id, taximask, innTriggerId
) VALUES (
    1001, 102, 'SellBuyBot', 1, 1, 0, 1, 0, 0,
    0,0,0,0,0,
    0,0,0,
    -8949.95, -132.50, 83.53, 0,
    0,0,0
);
```  

---

## Enable Modules (mod‑AHBot, etc.)

1. Edit each module’s `.conf` file under `~/azerothcore-wotlk/modules/*/conf/`.
2. Change `Enable = 0` → `Enable = 1` for the modules you want.
3. In `mod-AHBot.conf` set the `BotAccountId` (or similar) to the **account_id** from step 11.  

---

## Run the Servers (with *screen* for persistence)

```bash
sudo apt install screen -y

# Auth server
screen -S authserver
cd ~/azerothcore-wotlk
./acore.sh run-authserver
# detach: Ctrl‑A D

# World server
screen -S worldserver
cd ~/azerothcore-wotlk
./acore.sh run-worldserver
# detach when needed: Ctrl‑A D
```  
## Open Ports

1. Open ports 8085 and 3724 with ufw for LAN access.
2. Open ports 8085 and 3724 on your router for public access.
3. You can also use a meshnet like tailscale + nordvpn.
---

## Create an Admin Account (in‑game)

1. Attach to the world server console (`screen -r worldserver` if detached).  
2. Execute:

```text
account create admin <ADMIN_PASSWORD>
account set gmlevel admin 3 -1
```  

3. Edit `realmlist.wtf` in the WoW client folder (or `data/realmlist.wtf`)  

```
set realmlist <YOUR_PUBLIC_IP>
```  

4. Launch `WoW.exe` directly (bypass the Blizzard launcher) and log in with **admin / \<ADMIN_PASSWORD\>**.  

---

## 🎉 You’re ready!  

* Auth server → `./acore.sh run-authserver`  
* World server → `./acore.sh run-worldserver`  
* Connect the client to the IP you set in `realmlist.wtf`.  

---  

*Tip:* Keep the `screen` sessions running in the background, or set up systemd services for automatic start‑up after a reboot.  

---  
