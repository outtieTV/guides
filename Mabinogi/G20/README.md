---

# Mabinogi G20 Server Setup Guide

A complete guide to deploying, configuring, translating, and troubleshooting a Mabinogi Generation 20 (G20) private server environment.

---

## Architecture Overview

A complete server setup includes the following individual server components and binaries. They should be initialized in a specific sequence to maintain data integrity and networking handshakes.

* **Auth (Authenticator)**
* **XMLDB**
* **LoginServer**
* **Coordinator**
* **Channel Servers** (e.g., CH1, Housing Channel)
* **NPCClient** (Game Loop Processing Engines for core channels)
* **Messenger** (Typically ported/copied from G13)
* **PHP Account Creator** *(Optional)*

---

## Phase 1: Windows & Environment Readiness

### 1. Required Downloads

Before writing configs, acquire the following base tools and source files:

* **Server & Databases:** Mabinogi G20 Server files, G20 Unfixed SQL, G20 Fixed SQL, `uiupload.php`, and [G20 DB Server MySQL 8 Alternative](https://github.com/ktthai/G20-DB-Server).
* **Client Assets:** G20 Client Hotfix, ProjectM200JP Client, Language Patch, and Steam files *(if downloading older versions via Steam Depot)*.
* **Applications:** * Microsoft SQL Server 2022 & Microsoft SQL Server 2005 (with SP4 for legacy workflows)
* [SQLBackupAndFTP](https://sqlbackupandftp.com/)
* [MabiPack / MabiPacker 1.2.1](https://github.com/logue/MabiPack) or [MabiPack2](https://github.com/regomne/mabi-pack2)
* [DNSpy](https://github.com/dnspy/dnspy)
* Hex Editor (e.g., [HexD](https://sourceforge.net/projects/hexd/))
* [WinMerge](https://winmerge.org/)
* Web Server wrapper (e.g., XAMPP for serving PHP endpoints)



### 2. Manual Pre-processing

1. **SQL Merging:** Create a workspace folder. Drop the **G20 Unfixed SQL** files in, then extract the **G20 Fixed SQL** files directly over them, overwriting any duplicate definitions.
2. **Optimizing Duplication:** To minimize manual configurations and save disk space, utilize native Windows Symbolic Links (`mklink /d`) for duplicate engine file paths across server folders (e.g., `loginserver`, `gameserver`, `npc client`, and `client`).

---

## Phase 2: Database Restoration & Configs

### 1. SQL Server Configuration

1. Open **SQL Server Configuration Manager**.
2. Set **MS SQL Server** and **SQL Server Browser** services to startup **Automatically** with Windows.
3. Navigate to Protocols for MSSQLSERVER $\rightarrow$ **TCP/IP**. Enable it and verify under the *IP Addresses* tab that all relevant interfaces and **IPAll** are configured to listen on Port `1433`.

### 2. Restoring the `.bak` Files

If you are working with older database structures, follow the installation sequence for legacy databases, checking installation log schemas for anomalies.

> [!TIP]
> If you encounter **MSI Error 1603** during the legacy components installation, consult the [Error 1603 Virtual Machine Hotfix](%23hotfix-sql-server-2005-install-error-1603) section at the bottom of this document.

1. Move all SQL database `.bak` files into the default Microsoft SQL Server `/backup` folder directory.
2. Open **SQL Server Management Studio (SSMS)**.
3. Right-click **Databases** $\rightarrow$ **Restore Database...**
4. **General Tab:** Select *From Device*, find your target file (e.g., `db_shop_sync.bak`), and type the corresponding target name into the Destination Database input field.
5. **Options Tab:** To avoid physical filename collision paths between separate databases, rename the logical structural paths by appending `_1`, `_2`, or `_3` to the internal filenames while ensuring extensions (`.mdf`/`.ldf`) remain completely intact.

### 3. Connection String Reference (SQL Mode)

When decoupling engines using programmatic database states, make sure your configurations supply the exact connection keys requested by `GetConnectionString()`. Use **DNSpy** to inspect compiled binaries if hidden strings throw errors.

#### `XMLDB /config.xml` Requirements

Ensure the following connection profiles exist inside your XML configuration:

```text
account, accountref, character, bank, prop, guild, websynch, itemidpool, 
charidpool, propidpool, loginidpool, guildidpool, bididpool, castle, 
house, memo, chronicle, ruin, shopadvertise, houseguestbook, dungeonrank, 
channelingkeypool, promotionrank, mailbox, farm, bid, event, worldmeta, 
wine, countryreport, loginoutreport, husky, privatefarm, facilityidpool,
privatefarmrecommend, scrapbook, commerce, commercesystem, recommend, 
commercecriminal, goldlog, linkedapcharacter, equipmentcollection, 
soulmate, personalranking, setinfo, mabinovel, mabinovelboard, 
helppointrank, inviteevent, defaultconnection

```

#### `Authenticator /config.xml` Requirements

Map your configuration targets explicitly under `<sql><connections>` and `<itemshop>`:

```xml
<sql>
  <connections>
    <fantasylifeclub> </fantasylifeclub>
    <premiumpack> </premiumpack>
    <pceventcoupon> </pceventcoupon>
    <charactercard> </charactercard>
    <petcard> </petcard>
    <gift> </gift>
    <freeservice> </freeservice>
    <nexonidmap> </nexonidmap>
    <passwordchange2010> </passwordchange2010>
    <webdb> </webdb>
  </connections>
</sql>

<itemshop gameNumber="9">
    <domains domainNumber="9" serverName="mabicn27"/>
    <sql server="127.0.0.1" database="db_shop_sync" user="mabishop" password="password"/>
</itemshop>

```

#### `DB_XMLServer /config.xml` Mapping

Open `/DB_XMLServer/_config.xml`, extract the validated SQL credentials, and paste them into `/DB_XMLServer/config.xml`. Define your database schema details as follows:

* **Server Parameter:** Set to `"COMPUTER_NAME\INSTANCE_NAME"` (e.g., `Jon_Laptop\SQLExpress`).
* **Database Names:** Ensure each mapping targets its valid restored structural database.
* **Authentication:** User set to `"sa"`, with your designated system administration password.

---

## Phase 3: Server Translation & Modification

### 1. Packaging Server Data

To translate local string pools cleanly, repack data structures using the **MabiPack** process flow:

1. Create two working directories: `\Downloads\language` and `\Downloads\lang_eng`.
2. Copy your client's `lang_eng.pack` and the server's `gameserver\package\language.pack` into `\Downloads`. Unpack both.
3. Open `locala.7z`. Extract its internal payload to `\Downloads\language` ensuring files settle directly under `\Downloads\language\data\local`.
4. Drag the `local` folder inside the 7zip window directly into `\Downloads\language\data` to overwrite system files like `china.world.txt` and corresponding scripts.
5. Copy those identical local assets out of the 7z structure directly into your system runtime path: `C:\mabinogi\server\gameserver\data`.
6. **Crucial:** Wipe the temporary memory cache folder entirely: `C:\mabinogi\server\gameserver\cache`.
7. Transfer UI/interface modifications from `\Downloads\lang_eng` directly into `\Downloads\language`.
8. Open **MabiPack**, click **Pack Folder**, and target:
* **Input Path:** `\Downloads\language\data`
* **Output Path:** `\Downloads\lang_eng.pack` (Overwrite)
* **Parameters:** Version `243`, Compression `Level 1`.


9. Right-click the newly generated `lang_eng.pack` $\rightarrow$ **Properties** $\rightarrow$ Check **Read-only**.
10. Distribute this compiled asset by renaming it to `language.pack` and pasting it over the original packages in these three locations:
* `C:\mabinogi\client\package\language.pack`
* `C:\mabinogi\server\gameserver\package\language.pack`
* `C:\mabinogi\server\npcserver\package\language.pack`



### 2. UI Server Translation & Sync Integration (`UiUpload.php`)

To support UI state saving, establish a web handler for client payloads.

1. Drop the following PHP script block onto an active web environment layout (such as XAMPP). It will automatically generate local directories to handle client UI changes:

```php
<?php
$charId = $_POST['char_id'];
$nameServer = $_POST['name_server'];
$uiLoadSuccess = $_POST['ui_load_success'];
$group = substr($charId, -3);
$file_tmp = $_FILES["ui"]["tmp_name"];
$target_dir = "ui/" . $nameServer ."/" .$group ."/";
$target_file = $target_dir . basename($_FILES["ui"]["name"]);

if(!is_dir($target_dir)){
    mkdir($target_dir, 0755, true);
} 

if (move_uploaded_file($_FILES["ui"]["tmp_name"], $target_file)) {
    echo "The file ". basename( $_FILES["ui"]["name"]). " has been uploaded.";
} else {
    echo "Sorry, there was an error uploading your file.";
}
?>

```

2. Startup your local web server.
3. Open **MabiPacker**, navigate to the **Unpack** tab, and open your client asset package: `ProjectM200JPClient\Client\package\198_full.pack`.
4. Click **Check Content** to open the embedded virtual package browser.
5. Locate `data\db\urls.xml`. Click **Export** in the top right and save the file locally.
6. Open `urls.xml` in a text editor, find the `<URL Locale="japan">` node string section, and edit the UI network pathways to resolve back to your web service layout:
```xml
UploadUIPage="http://127.0.0.1/UiUpload.php"
DownloadUIAddress="http://127.0.0.1/ui/"

```


7. Save and drop the updated XML file directly into the local physical folder path overriding the pack structure: `ProjectM200JPClient\Client\data\db\urls.xml`.
8. *Verification Test:* Launch the game client, shift windows or customize your hotbar layout, and exit the client application. Log back in to verify the coordinate configurations download from your server successfully.

---

## Phase 4: Initialization & Engine Interfacing

### 1. Service Orchestration Script (`startall.bat`)

To initialize your background architecture cleanly, create a master execution routine script named `startall.bat`. Use the runtime parameters detailed below, making sure to inject adequate `timeout` delays between lines so processes don't step on each other during boot.

```batch
@echo off
:: Note: Use "GM KR Test, China" parameter properties for server flags.
:: Client launch routines must call "Regular, China".

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

:: Initialize Channel processing subsystems
start "" "C:\mabinogi\server\npcclient\npcclient.exe" "GM KR Test, China"

```

### 2. Provisioning Core Accounts

Use the application `xmldb_accountmanager` to provision administrative handles and foundational processing accounts.

#### Base System NPC Account Configuration

1. Generate an account using the following keys:
* **Account Username Name:** `npc1`
* **Account Password String:** `fpswl` *(Hex value representation in uppercase MD5: `AD899A74D1AA830BF77625F4328118DC`)*
* **Security Authority Level Flag:** `npc`


2. Open and verify matching data lines inside your engine configuration file: `npcclient -> NPCClient.xml`. Ensure usernames, hashes, and parameters balance perfectly.

#### Base GameMaster Account Configuration

1. Generate an account using the following parameters:
* **Account Username Name:** `admin`
* **Account Password String:** `admin`
* **Security Authority Level Flag:** `boss`



### 3. Synchronizing the NPC Client Engine

1. Launch the standalone pipeline: `243_C/client start.bat`.
2. Log into your server using the `npc1` account credentials. Create a default entity named `npc`.
3. Once spawned into the game world, open the command input terminal console and run the following placement parameters:
```text
>move /r:15 /x:1000 /y:1000
>set_condition /a:23

```


4. Close the processing client wrapper manually.
5. Monitor the primary background processing service window at `243_S/npc client` until the output log displays the confirmation flag: `SYS> ---------- Processing-Commands End ----------`.

### 4. Player Client Initialization

1. Provision a standard player record utilizing your account tools.
2. Navigate to `gameserver/server.ini` (along with any matching `server.ini` configurations in adjacent service folders) and modify `features.xml` values from `GM Test China` to `Regular, China`.
3. Execute your local client startup file: `start.bat` $\rightarrow$ `client.exe`.
4. Log into your custom player account and complete the default entry tutorial areas entirely to establish basic data properties.
5. *Optional GM Activation:* If using your `admin` character profile, elevate game credentials by executing this sequence in the client terminal:
```text
>set_title /add /id:60000

```



---

## Technical Reference & Core Asset Modification

### Password Hash Decryption Mechanics

If you need to audit or manually trace passwords saved within the G20 database schema, reverse the encryption layers using the following workflow:

1. Pass the raw system string hash through an automated cryptographic analyzer to verify it resolves cleanly against an **MD5** signature scheme (e.g., via [Hashes.com Check](https://hashes.com/en/decrypt/hash)).
2. Decode the verified hexadecimal content using an encoding transform recipe configured for **UTF-16LE** extraction rules (such as this [CyberChef Recipe Matrix Tool Example](https://gchq.github.io/CyberChef/%23recipe%3DFrom_Hex(%27None%27)Decode_text(%27UTF-16LE%2520(1200)%27)%26input%3DNzAwMDYxMDA3MzAwNzMwMDc3MDA2ZjAwNzIwMDY0MDA)).

### Constructing a DevClient Node

If you require a specialized debug client alongside your server topology, transform a duplicate copy of your active NPC client framework:

1. Duplicate your operational NPC Client folder directory to create a dedicated working workspace.
2. Navigate into `data/db` within that workspace and wipe all artificial intelligence asset profiles completely.
3. Copy across your raw `.pack` archives directly out of your standard client game package root directory.
4. Locate and delete the configuration file `NPCClient.xml` entirely.
5. Open your boot instructions and adjust the target initialization argument properties, changing the boot flag from code `1214` to code `1622`.

### Administrative Tool Repositories & Commands

* **Command References:** Detailed spreadsheets tracking layout systems can be fetched directly via Discord's secure archival CDN links:
* [Master Spreadsheet Commands Matrix](https://cdn.discordapp.com/attachments/557427921107550221/1011627956663242752/Commands.xlsx)
* [Functional Operational Info Details Guide](https://cdn.discordapp.com/attachments/557427921107550221/1011627956336066580/Commands_Info.xlsx)


* **Third-Party Proxy Tools:** For advanced connection routing and troubleshooting, refer to [Morrighan Proxy](https://github.com/exectails/Morrighan), [Fetitor Releases](https://github.com/exectails/Fetitor/releases), or query structures using the [Mabi DataHelper Archive Engine](https://yai.rydian.net/mabidatahelper/).

---

## Troubleshooting & Global Hotfixes

### Hotfix: SQL Server 2005 Install Error 1603

When configuring legacy databases, this error can crop up due to OS permission conflicts. In worst-case scenarios, a clean OS reinstall is required, but you can bypass this error using a 64-bit sandbox environment.

*Video Reference Alternative:* [SQL Server 2005 Configuration Steps Walkthrough](https://www.youtube.com/watch?v=cj859zcWhEM)

*Manual Resource Cleanup:* [AgileIT Complete SQL Server Manual Uninstall Instructions](https://agileit.com/news/manual-uninstall-of-sql-2005-32bit-64bit-sql-server-or-express-including-reporting-services/)

#### Workaround Steps

1. Build an isolated virtual machine running **Windows 7 64-bit**.
2. Install **SQL Server 2005 Express Edition** followed by the **SQL Server 2005 SP4** package updates inside that virtual environment.
3. Extract the cleanly generated system binary tracking components `sqlservr.exe` and `sqlos.dll` out of the VM environment and drop them into an accessible shared host server folder.
4. Run the native **SQL Server 2005 Express** installation routing framework directly on your primary host operating system.
5. When the system halts on the validation error panel, manually inject your copied versions of `sqlservr.exe` and `sqlos.dll` directly over the problematic files located deep inside your host machine's `Program Files\Microsoft SQL Server\...` instance path folder structure.
6. Return to the error dialog installer layout screen and click **Retry** to finalize setup.
7. Ensure mixed-mode security configurations are active on your instance. Refer to the [StackOverflow SQL Mixed Authentication Activation Guide](https://stackoverflow.com/a/5723880).

### Hotfix: Missing System Parameters & Feature Access

If you encounter runtime map blockages, cannot initialize trading/commerce paths, or find that the Pon currency interface isn't responding:

1. Audit configuration properties across your key infrastructure binaries: `Login`, `Game`, `NpcClient`, and `Coordinator`.
2. Verify or add the parameter mapping path string to ensure data attributes load explicitly:
```ini
file://data/features.xml=Regular, China

```



### Hotfix: Resolving Dungeon Pass Lock Issues

If the Dungeon Unlimited Pass item fails to work as expected, a data conflict between the legacy and 2016 renewal dungeon rules is likely the cause.

1. Open the server asset mapping database file: `gameserver\data\db\dungeondb2.xml`.
2. Locate the 2016 Renewal database blocks and switch the parameter flag from `dungeonpassable="true"` to `"false"`.
3. Locate the legacy version database blocks inside that same tracking document and change their parameters from `dungeonpassable="false"` to `"true"`.

### Hotfix: Tin's Magic Stone Script Block

If Tin's Magic Stone item does not activate properly when used, ensure your channel routing mapping table is explicitly defined.

1. Open `ServerInfo.ini` across all server engine folders.
2. Update or add the following path statement configuration variable:
```ini
CHANNELGROUPFILE = data\db\ChannelInfo.xml

```



### Hotfix: Post-Unpack Client Launch Failures

If unpacking your client's `.pack` files prevents the application from launching, verify that your translation directory hierarchy matches the expected structure.

* The unpacked payload content extracted out of your `language.pack` files must match the following server root subfolder path: `gameserver\data\local\`

### Hotfix: Changing the Server / Channel Names

To change your channel and server names from the default layout (`TEST_WORLD` / `mabilocalserver`):

1. Open and modify the core allocation document: `gameserver\data\local\xmlchnnelindexinfo.china.txt`.
2. Search your server engines and replace any instances of the target string name `'TEST_WORLD'` with your custom name string across these three core files:
* `ServerInfo.ini` (Located inside your primary server and Coordinator workspace folders)
* `NPCClient.xml` (Located inside your active NpcClient layout directory)
* `server.ini` (Review all active operational folder structures)



### Hotfix: Delayed Monster-Player Recognition (Lag & Desync)

If you notice a consistent delay (up to 4 seconds) before monsters recognize or react to player actions:

1. Check the rendering frame rate output directly inside your **NpcClient** status window.
2. If the loop metrics fall consistently **under 35 FPS**, the engine processing layers are choking. To fix this, migrate your host environment onto a dedicated bare-metal machine running native Windows, as nested hypervisors and low-spec virtual environments often lack sufficient performance for the G20 loop engines.

### Hotfix: World Entry Hang (Stuck After Login Success)

If account verification succeeds but the loading client hangs indefinitely before fully rendering the game world, the server is likely still completing its initial boot tasks.

* Open your active running instance of the **NpcClient** status window interface and wait. The client will block map routing access until the initialization sequence logs this specific tracking signature line:
```text
SYS> ---------- Processing-Commands End ----------

```



### Hotfix: Restoring the Underground Waterway Quest Passwords

If players are blocked from progressing past the core underground canal investigations due to broken script responses:

1. Navigate into your server script logic directory: `gameserver/data/script/dungeon2`.
2. Open these seven target mint tracking file elements in a script editor:
* `701015_bossmission2reddragon.mint`
* `701016_bossmission3claimhsolas.mint`
* `730103_eventclaimhsolas.mint`
* `792203_claimhsolas.mint`
* `793004_investigatecanal.mint`
* `793005_investigatecanal2.mint`
* `793006_meetnuadha2.mint`


3. Locate the following structural logic command call line:
```javascript
_dungeon.SetData(`password`, password2);

```


4. Replace that expression block entirely with this concatenated variable handling routine:
```javascript
password1 = "Secret";
password2 = " Password";
string password3 = password1+password2;
_dungeon.SetData(`password`, password3);

```


*This modification sets all active dungeon gating checks across those operational instances to evaluate successfully against the universal string profile password: `"Secret Password"`.*

### Hotfix: Injecting the Flown Sky Lantern Feature Event to `243_S`

To manually append missing Sky Lantern performance files into your G20 structure, add the following text parameters to your data folders.

#### File 1: Add to `skillinfo.xml`

```xml
<Skill SkillID="50070" SkillEngName="Flown Sky Lantern" SkillLocalName="_LT[xml.skillinfo.4488]" SkillType="0" SkillCategory="100" DescName="FlownSkyLantern" UIType="0" MaxStackNum="1" AutoStack="False" StackLimitTime="0" UseType="0" RaceBasic="0" BasicType="1" IsHidden="False" IsSpecialAction="True" LvZeroUsable="True" OnceALife="False" TransformType="0" ParentSkill="0" TargetRange="0" TargetPreparedType="0" ProcessTargetType="0" ImageFile="data/gfx/image/GUI_icon_skill_003.dds" PositionX="3" PositionY="11" ClosedDesc="_LT[xml.skillinfo.4491]" SkillDesc="_LT[xml.skillinfo.4492]" PrepareLock="lock(walk,run)" WaitLock="lock(useskill,walk,run,stance,pickndrop,talktonpc)" ProcessLock="lock(useskill,walk,run,stance,pickndrop,talktonpc)" AvailableRace="7" PublicSeason="1301" Public="0" Venturer="1" Knight="1" Wizard="1" Archer="1" Merchant="1" Alchemist="1" Fighter="1" Bard="1" PuppetMaster="1" travel="1" combat="1" magic="1" archery="1" commerce="1" battlealchemy="1" fight="1" music="1" puppet="1" lance="1" bless="1" transmutealchemy="1" cook="1" blacksmith="1" sewing="1" pharmacy="1" carpentry="1" dualgun="1" druid="1" boreadae="1" vate="1" masterchef="1. 중립스킬" treasurehunter="1. 중립스킬" ninja="1. 중립스킬" chainslash="1. 중립스킬" pethandling="1. 중립스킬" magigraphy="1. 중립스킬" /> 

<Skill SkillID="50071" SkillEngName="Flown Sky Lantern Hidden" SkillLocalName="_LT[xml.skillinfo.4489]" SkillType="0" SkillCategory="0" DescName="FlownSkyLantern" UIType="0" MaxStackNum="1" AutoStack="False" StackLimitTime="0" UseType="0" RaceBasic="1" BasicType="0" IsHidden="True" IsSpecialAction="False" LvZeroUsable="True" OnceALife="False" TransformType="0" ParentSkill="0" TargetRange="0" TargetPreparedType="0" ProcessTargetType="0" ImageFile="data/gfx/image/GUI_icon_skill_003.dds" PositionX="3" PositionY="11" PrepareLock="lock(walk,run)" WaitLock="lock(useskill,walk,run,stance,pickndrop,talktonpc)" ProcessLock="lock(useskill,walk,run,stance,pickndrop,talktonpc)" AvailableRace="7" PublicSeason="1301" Public="0" Venturer="1" Knight="1" Wizard="1" Archer="1" Merchant="1" Alchemist="1" Fighter="1" Bard="1" PuppetMaster="1" travel="1" combat="1" magic="1" archery="1" commerce="1" battlealchemy="1" fight="1" music="1" puppet="1" lance="1" bless="1" transmutealchemy="1" cook="1" blacksmith="1" sewing="1" pharmacy="1" carpentry="1" dualgun="1" druid="1" boreadae="1" vate="1" masterchef="1. 중립스킬" treasurehunter="1. 중립스킬" ninja="1. 중립스킬" chainslash="1. 중립스킬" pethandling="1. 중립스킬" magigraphy="1. 중립스킬" />

```

#### File 2: Add to `skillleveldescription.xml`

```xml
<FlownSkyLantern race="base"> <SkillLevelDetail SkillLevel="0" CharacterPrepareTime="2000" PrepareTime="2000" AbilityNecessary="0" StaminaNecessary="0" StaminaModPreparing="0" StaminaModWaiting="0" StaminaModProcessing="0" ManaNecessary="0" ManaModPreparing="0" ManaModWaiting="0" ManaModProcessing="0" CombatPower="0" StackPerCast="1" EffectDescription="_LT[xml.skillleveldescription.37191]" Conditions="_LT[xml.skillleveldescription.37187]" XMLData="&lt;xml meshname=&quot;prop_event_lantern_01&quot; /&gt;" BonusLife="0" BonusMana="0" BonusStamina="0" BonusSTR="0" BonusINT="0" BonusDEX="0" BonusWill="0" BonusLuck="0" AttackRange="0" OptionApplyDmgMin="0" OptionApplyDmgMax="0" OptionApplyCritical="0" OptionApplyBalance="0" OptionApplyWoundMin="0" OptionApplyWoundMax="0" /> </FlownSkyLantern> 

```

#### File 3: Add to `basiceventlist.xml`

```xml
<Event name="pungdeung_2015" start_msg="_LT[xml.basiceventlist.1049]" progress_msg="_LT[xml.basiceventlist.1050]" end_msg="_LT[xml.basiceventlist.1051]" />

```

#### File 4: Add to `basiceventlist.china.txt`

```text
1049    Start the Flown Sky Lantern Event.
1050    The Flown Sky Lantern Event is in progress.
1051    End the Flown Sky Lantern Event.

```

### Hotfix: Display Formatting Errors (e.g., Fixing `10000 Gold`)

To repair layout presentation tracking bugs inside the client where high numeric values display incorrectly, open `patch2.dat` using your chosen **Hex Editor** tool. Locate the binary hex blocks listed below and substitute them with the replacement values:

```text
// Routine 3 Modification
Search Block:  8B 45 10 48 83 F8 07 0F 87 C6 01 00 00
Replace With:  E9 8F 01 00 00 90 90 0F 87 C6 01 00 00

// Routine 4 Modification
Search Block:  8B 49 50 81 C1 E7 03 00 00 B8 D3 4D 62 10 F7 E1 8B C2 C1 E8 06 C3
Replace With:  8B 49 50 81 C1 00 00 00 00 B8 D3 4D 62 10 F7 E1 8B C2 8B C1 C3 90

// Routine 5 Modification
Search Block:  56 8B F1 57 8B 7E 54 E8 64 FE FE FF 84 C0 74 1E 6A 0A 8B CE E8 57 FC FF FF 69 C0 E8 03 00 00 03 C7 B9 00 00 00 00 0F 98 C1 49 23 C1 EB 0A 33 C0 85 FF 0F 98 C0 48 23 C7 8D 90 E7 03 00 00 B8 D3 4D 62 10 F7 E2 8B C2 5F C1 E8 06 5E C3
Replace With:  8B 49 54 81 C1 00 00 00 00 B8 D3 4D 62 10 F7 E1 8B C2 8B C1 C3 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90

```

---

## Database Administration & Maintenance

### 1. Cleaning Out Specific Character Items

If a corrupt or illegal object breaks a character's inventory, you can prune it using direct database rows in SSMS:

1. Navigate to your primary game records database database tables.
2. Open the item storage space matrix tables that match the target object's slot constraints: `Charitemlarge`, `Charitemhuge`, or `Charitemsmall`.
3. Filter your search queries utilizing the `Class ID` derived from the unique core asset database template key.
4. *Safety Check:* To prevent deleting identical items belonging to other players, always double-check contextual parameters like creation date timestamps and color parameters before confirming deletion.
5. Highlight the targeted identification data row inside the SSMS grid panel layout workspace view, right-click the row selection indicator, and select **Delete**.

### 2. Deep Structural Database Corrections

If complex application crashes pop up because the database schema is slightly older than your G20 server files:

1. Decompile the compiled service tracker binary component `xmldb.exe` to review its data types.
2. Cross-reference the explicit native parameter datatypes requested by the executable code against the data properties assigned to your physical SQL columns. Correct any mismatches.
3. Rebuild approximately 3 missing procedure handlers within the relational engine layout rules to resolve execution pipeline faults.

---

## Appendix: Client Extraction via Steam

If you need to source explicit legacy game assets directly from official distributions, utilize the Steam platform architecture tools:

1. Apply the patch solution handler engine onto your local target directory: [SteamManifestPatcher Release Pipeline](https://github.com/fifty-six/zig.SteamManifestPatcher/releases).
2. Open your operating system's *Run* dialog box ($Win + R$) and execute this system instruction link protocol call: `steam://open/console`
3. Target depot downloads using the platform console parameters:
```text
download_depot <appid> <depotid> [<new manifestid>] [<old manifestid>]

```


* **To download the oldest available client build structure:**
```text
download_depot 212200 212201 5378056672283508653

```


* **To download the latest release branch package:**
```text
download_depot 212200 212201 1110034208523718321

```


* **To isolate and capture modified tracking data files across versions:**
```text
download_depot 212200 212201 1110034208523718321 1877343873669484515

```




4. Once download progress clears, the system console logs the absolute file path destination (e.g., `"C:\Program Files (x86)\Steam\steamapps\content\app_212200\depot_212201"`). You can track manifest histories through the online [SteamDB Manifest Tracker Database Utility](https://steamdb.info/depot/212201/manifests/).

---

## Known Bugs & Unresolved Limitations

The following bugs exist in this version of the G20 server release and require manual codebase adjustments:

* **Burning with Vengeance Quest line:** The *Sword of Vengeance* encounter fails to generate enemy actor elements. Monsters do not spawn. *(Fix require editing file `731009_milliatraning01.mint` inside your game scripts folder to force active creature spawning loops).*
* **Carpentry Skill Tree Limitations:** Carpentry benches do not register interactions or function correctly within the world space.
* **Homestead Farming Systems:** Attempting to cultivate poisonous herb profiles inside your personal homestead map yields an "unauthorized action" rejection error block.
