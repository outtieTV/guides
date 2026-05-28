**MabiBook & MabiGuild Setup Guide**  

> The steps below assume you already have the G22 server/client installed (see the main G22 guide). They focus only on getting **MabiBook** (in‑game book content) and **MabiGuild** (guild creation) working on a local XAMPP web server.

---  

## 1️⃣ Install XAMPP (only Apache)

1. Download XAMPP from <https://www.apachefriends.org/> (choose the Windows version).  
2. Run the installer and **select only “Apache”** (uncheck MySQL, FileZilla, Tomcat, etc.).  
3. Finish the install – XAMPP will be placed in `C:\xampp` by default.  
4. Start the **Apache** service from the XAMPP Control Panel; the status indicator should turn green and show “Running”.

---  

## 2️⃣ Deploy the Book Files

1. Create a folder for the book data inside the web root, e.g.:

   ```
   C:\xampp\htdocs\Book\Data\china\
   ```

2. Copy all of your **MabiBook** HTML/JSON/XML files (the “book contents”) into that folder.  
   The final path structure should match the URL you will give the client, for example:

   ```
   http://<your‑ip>/Book/Data/china/Chapter01.xml
   ```

3. Verify the files are reachable by opening a browser and navigating to the base URL:

   ```
   http://<your‑ip>/Book/Data/china/
   ```

   You should see a directory listing or be able to open a specific file.

---  

## 3️⃣ Point the Client to the Book URL

1. Open the **client’s batch startup file** (`start.bat` in `RCSWork\Client` or wherever `Client.exe` is launched).  
2. Add (or edit) the `BookContentsAddress` parameter so it points to the URL you just set up, for example:

   ```bat
   start Client.exe code:1622 ver:200 logip:127.0.0.1 logport:21000 setting:"file://data/features.xml=Regular, China" BookContentsAddress="http://<your‑ip>/Book/Data/china/"
   ```

3. Save the file.

> **Note:** If the client does not already have a `SubLocale` entry, add it at the end of the command line:

   ```
   SubLocale="ServerGroup01"
   ```

   (replace `ServerGroup01` with the actual server group your client uses).

---  

## 4️⃣ Enable Guild Creation (MabiGuild)

### 4.1 Fix the `CreateGuild3` Stored Procedure

The original `dbo.CreateGuild3` procedure in the G20 database contains a line that can reject `NULL` or malformed expiration dates:

```sql
left(@expiration, 23)
```

Replace that line with the following logic, which validates the value and defaults to “one year from now” when it cannot be parsed:

```sql
WHEN TRY_CONVERT(datetime, @expiration) IS NULL 
    THEN DATEADD(year, 1, GETDATE()) 
    ELSE TRY_CONVERT(datetime, @expiration) 
END
```

**How to apply the change**

1. Open **SQL Server Management Studio** (or any query tool) and connect to the `MABINOGI_G20` database.  
2. Locate the `dbo.CreateGuild3` procedure (right‑click → Modify).  
3. Find the line that reads `left(@expiration, 23)` and replace it with the block above.  
4. Execute the script to save the modified procedure.

> This tweak allows the procedure to accept the empty `@expiration` field that the client sends when creating a guild, preventing the “date conversion failed” error that blocked guild creation on G20 databases.

### 4.2 (Optional) Verify Guild‑related Settings

| Setting | Typical value | Where to check |
|---------|----------------|----------------|
| `GuildCreateCost` | 5,000 gold | `ServerInfo.ini` or a custom `GuildConfig.ini` |
| `MaxGuildMembers` | 50 | `GuildLimits.ini` |
| `AllowCreateGuild` | `true` | `ServerInfo.ini` |

If any of these values are missing or set to `false/0`, edit the corresponding `.ini` file and restart the **login/server** stack.

---  

## 5️⃣ Test the Setup  

1. **Start the server stack** (loginserver, worldserver, otherserver) as described in the main G22 guide.  
2. **Launch the NPC client** and log in with an account that has sufficient gold.  
3. **Open the in‑game guild creation window** (or use the NPC command `CreateGuild <GuildName>`).  
4. If the guild is created successfully, you’ll see a confirmation message and the guild appears in the guild list.  

   - If you get an error about `expiration` or “invalid date”, double‑check the stored‑procedure edit in **4.1**.  
   - If the error mentions “insufficient gold”, adjust `GuildCreateCost` in the config files.

5. **Open the regular client** and verify you can view the book content:

   - Press **F1** (or the in‑game “Guide” button) to open the book.  
   - The client should load the chapters from the URL you set in **3**.  

   If the book appears blank, make sure the URL ends with a trailing slash (`/`) and that Apache is still running.

---  

## 6️⃣ Quick Checklist for MabiBook & MabiGuild  

- [ ] XAMPP Apache installed and running.  
- [ ] Book files placed in `C:\xampp\htdocs\Book\Data\<locale>\`.  
- [ ] `BookContentsAddress` parameter in the client launch command points to the correct URL.  
- [ ] `SubLocale` added to the client launch command if missing.  
- [ ] `dbo.CreateGuild3` stored procedure edited with the TRY_CONVERT logic.  
- [ ] Guild‑related `.ini` settings configured (cost, member limit, enable flag).  
- [ ] Server stack restarted after any config or DB changes.  
- [ ] Guild creation succeeds and book pages load in‑game.

---  

### 🎉 You’re Ready!

With XAMPP serving the book data and the `CreateGuild3` fix applied, your local G20/G22 environment can now:

* **Display custom in‑game books** (MabiBook).  
* **Create and manage guilds** (MabiGuild) without database‑date errors.

Happy testing, and enjoy your private Mabinogi world!
