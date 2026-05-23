## Building a Turtle‑WoW (MaNGOS) Server on Windows  

*All paths are examples; feel free to adapt them to your own folder layout.*

---  

### 1. Required Tools  

| Tool | Minimum version | Download / source |
|------|----------------|-------------------|
| **Visual Studio** | 2022 (or later – the guide assumes VS 2026) | <https://visualstudio.microsoft.com/> |
| **CMake** | 3.25.1 | <https://cmake.org/download/> |
| **OpenSSL** | 1.1.1s | Build from source (see §2) |
| **zlib** | 1.2.3 (pre‑compiled) | <https://sourceforge.net/projects/gnuwin32/files/zlib/1.2.3/> |
| **SDL2** | any recent release | <https://github.com/libsdl-org/SDL/releases> |
| **Recast/Detour** | 1.6.0 | <https://github.com/recastnavigation/recastnavigation/releases> |
| **ACE (Micro Release  8.0.5)** | 8.0.5 | <http://download.dre.vanderbilt.edu> |
| **MySQL** | 8.0 (latest) | <https://dev.mysql.com/downloads/mysql/> |

> **Tip:** Keep all third‑party libraries under a single root, e.g. `C:\local\`.  
> Add any required `bin` directories to the **system** `PATH` (see §8).

---  

### 2. Build OpenSSL 1.1.1s  

1. Download the source archive from the OpenSSL website.  
2. Follow the step‑by‑step guide:  
   <https://developers.lseg.com/en/article-catalog/article/how-to-build-openssl--zlib--and-curl-libraries-on-windows>  
3. Install the resulting `bin` folder (containing `libssl.lib`, `libcrypto.lib`, `ssleay32.dll`, `libeay32.dll`) to a location you will reference later, e.g. `C:\local\openssl-1.1.1s`.

---  

### 3. Install zlib  

1. Download **zlib‑1.2.3.exe** from SourceForge.  
2. Run the installer and choose a folder such as `C:\local\zlib`.  
3. Verify that `zlib.lib` and `zlib.dll` appear in the `lib` and `bin` sub‑folders.

---  

### 4. Compile Recast/Detour with Visual Studio  

1. Extract the **recastnavigation‑1.6.0** source to `C:\local\src\recastnavigation-1.6.0`.  
2. Open the solution file `RecastDemo.sln` (or `RecastDemo.sln` generated after running the provided `CMakeLists.txt` once) with Visual Studio.  
3. **Retarget** the solution to your installed VS version (e.g., VS 2026).  
4. Set **Configuration** → **Release**, **Platform** → **x64**.  
5. Build **All Projects**. The resulting libraries (`Recast.lib`, `Detour.lib`, etc.) will be placed in `C:\local\recast-1.6.0\Release`.

> *Although the original project ships a CMake build, compiling directly with VS eliminates the extra CMake step and matches the requirement to use Visual Studio for all builds.*

---  

### 5. Install SDL2  

1. Download the latest **SDL2‑x64‑VS** package from the official releases page.  
2. Extract it to `C:\local\SDL`.  
3. Add `C:\local\SDL\lib\x64` and `C:\local\SDL\bin` to the system `PATH`.

---  

### 6. Compile ACE Micro Release  8.0.5  

1. Download **ACE‑8.0.5‑full.zip** from <http://download.dre.vanderbilt.edu>.  
2. Extract to `C:\local\src\ACE`. The solution file `ACE_vs2022.sln` should be at `C:\local\src\ACE\ACE_vs2022.sln`.  
3. Open the solution in Visual Studio and **retarget** it to VS 2026.  
4. Set **Configuration** → **Release**, **Platform** → **x64**.  

#### Required source patches (VS 2026 compatibility)

* **`ace/config.h`** – create this file in `C:\local\src\ACE\ace` with the single line:  

  ```c
  #include "ace/config-win32.h"
  ```  

* **`ace/Singleton.h`**, **`ace/Singleton.inl`**, **`ace/Singleton.cpp`** – add the `noexcept` specifier to the destructor, move‑constructor and move‑assignment operators.  

5. Build the entire solution (733 projects).  
6. Set the system environment variable **ACE_ROOT** to `C:\local\src\ACE`.

---  

### 7. Obtain and Prepare the Turtle‑WoW Source  

1. Clone the repository:  

   ```bash
   git clone https://github.com/Penqle/tortoise-wow.git F:\Servers\turtlewow\tortoise-wow-main
   ```  

2. **Client version patch** – edit `src/server/realmlist.cpp` and change the `static RealmBuildInfo ExpectedRealmdClientBuilds[] =` from `7199` to `7207`.  
3. Adjust the CMake configuration files so they point to the locations you used in the previous steps:  

   * `CMakeLists.txt` – set `OPENSSL_ROOT_DIR`, `ZLIB_ROOT`, `SDL2_DIR`, `RECAST_ROOT`, `ACE_ROOT`.  
   * `cmake/FindACE.cmake` – ensure it uses the `ACE_ROOT` variable.  

---  

### 8. Configure System Paths  

Add the following directories to the **system** `PATH` (or to a developer‑only path variable):  

```
C:\local\openssl-1.1.1s\bin
C:\local\zlib\bin
C:\local\SDL\bin
C:\local\recast-1.6.0\Release
C:\local\src\ACE\bin\Release
```

Confirm each DLL is discoverable from a plain command prompt (e.g., `openssl version`).

---  

### 9. Generate and Build the MaNGOS Solution **with Visual Studio**  

1. Create a dedicated build folder, e.g. `F:\Servers\turtlewow\tortoise-wow-build`.  
2. Run **CMake** GUI *only* to generate the Visual Studio solution (no actual compilation):  
3. Open the generated solution `TurtleWoW.sln` in **Visual Studio 2026**.  
4. Choose **Release** | **x64**, run **Clean Solution**, then **Build Solution**.  

   * The binaries `mangosd.exe` and `realmd.exe` will appear in  
     `F:\Servers\turtlewow\tortoise-wow-build\bin\Release`.  
   * Copy `ACE.dll` from the ACE build output into the same folder, overwriting any existing copy.

---  

### 10. Patch the Server Binaries  

1. Download the patch archive:  

   <https://www.mediafire.com/file/bpqqxrglydurpmq/patches.rar>  

2. Extract the contents to the **server patch folder**  

   ```
   F:\Servers\turtlewow\tortoise-wow-build\bin\Release\patches
   ```  

   (Create the `patches` folder if it does not exist.)  

3. The server will load these files at runtime.

---  

### 11. Set Up the MySQL Database  

1. Install **MySQL 8.0** and start the service.  
2. Create a dedicated user (e.g., `mangos` with a strong password) and a fresh database.  
3. Import the core schema:  

   ```bash
   mysql -u mangos -p < F:\Servers\turtlewow\tortoise-wow-main\sql\create_databases.sql
   ```  

4. Load all base data scripts:  

   ```bash
   for %%f in (F:\Servers\turtlewow\tortoise-wow-main\sql\base\*.sql) do (
       mysql -u mangos -p world %%f
   )
   ```  

5. The first run of `mangosd.exe` will automatically apply any pending updates.

---  

### 12. Client Configuration  

1. Edit the client’s `realmlist.wtf` (found in the WoW installation directory) so that it points to the local server:  

   ```
   set realmlist 127.0.0.1
   ```  

2. Copy the server‑provided **patches** (step 10) into the client’s `Data` folder if the client also expects them.  Ex: "F:\Servers\turtlewow\TurtleWoW 1172 Client\Data" Do not copy to client\Data\patches
3. Launch `WoW.exe`. The client should connect to `127.0.0.1` and load the Turtle‑WoW world.
---  

### 13. Quick‑Start Checklist  

| ✅ | Item |
|----|------|
| 1 | Visual Studio, CMake, OpenSSL, zlib, SDL2 installed |
| 2 | ACE compiled and `ACE_ROOT` set |
| 3 | Recast/Detour compiled **with Visual Studio** |
| 4 | Turtle‑WoW source patched to client build **7207** |
| 5 | CMake used only to generate a VS2026 solution |
| 6 | `mangosd.exe`, `realmd.exe`, and `ACE.dll` in **Release/x64** bin folder |
| 7 | Server patches placed in `bin\Release\patches` |
| 8 | MySQL database created and core SQL imported |
| 9 | Client `realmlist.wtf` points to `127.0.0.1` |
| 10| Server binaries started (`realmd.exe` → `mangosd.exe`) |

All steps completed → your Turtle‑WoW private server should be up and running. Happy testing!
