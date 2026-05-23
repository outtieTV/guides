Other guides on this forum appeared to be for port forwarding and such instead of just playing LAN-only with family and friends, so I wrote this.<br />
<br />
Getting Windows Ready:<br />
	* Download and install Java JDK 11 from Bell-SW.com for an Offline Installer<br />
		https://bell-sw.com/pages/downloads/#jdk-11-lts<br />
		Open cmd.exe as admin and set java home to your bellsoftware install location:<br />
			setx -m JAVA_HOME "C:\Program Files\BellSoft\LibericaJDK-11"<br />
	* Download and install MySQL Server and Client 5.7<br />
		https://dev.mysql.com/downloads/windows/installer/5.7.html<br />
		Ensure that MySQL is running on port 3306 with username root and no password.<br />
	* Download and install HeidiSQL<br />
		https://www.heidisql.com/<br />
	* Allow Ping through Windows Firewall<br />
		https://www.thewindowsclub.com/how-to-allow-pings-icmp-echo-requests-through-windows-firewall<br />
	* Turn Windows Features on or off:<br />
		Telnet Client (so you can type telnet 10.0.x.x 43595 to test if the port is open)<br />
	* File Explorer Options:<br />
		Uncheck Hide extensions for known file types<br />
	* System Settings -> Network:<br />
		Find your internal ip (should be in the format 192.168.x.x or 10.0.x.x)<br />
		Set your internal ip to be static<br />
			https://www.howtogeek.com/19249/how-to-assign-a-static-ip-address-in-windows/<br />
	* Download Visual Studio Community 2022 and install it with C# Development packages<br />
		https://visualstudio.microsoft.com/vs/community/<br />
	
<br />
Getting the Server Ready:<br />
	* Download 2009scape master.zip<br />
		https://gitlab.com/2009scape/2009scape/-/archive/master/2009scape-master.zip<br />
	* Create a directory:<br />
		C:/2009scape<br />
	* And extract 2009scapemaster.zip to the directory<br />
	* Change C:/2009scape/Server/Worldprops/default.conf<br />
		[server]<br />
		use_auth = true<br />
		persist_accounts = true<br />
		noauth_default_admin = true<br />
		watchdog_enabled = false<br />
		[world]<br />
		debug = false<br />
		dev = false<br />
		start_gui = false<br />
		daily_restart = true<br />
	and other settings to your desire<br />
<br />
	* Ensure that MySQL is running by pressing Windows key -> type "Services" no quotes -> MySQL Server<br />
	* Launch HeidiSQL and connect to mysql on port 3306 username root no password.<br />
	* Press file -> load sql and run C:\2009scape\Server\db_exports\global.sql<br />
	<br />
	* Run run-server.bat in C:/2009scape and let it compile. Might take a bit<br />
	* Allow java jdk 11 through firewall for private and public internet<br />
	
<br />
Getting the Client Ready:<br />
	* Download Saradomin Launcher from github (edit: official client compiles successfully now):<br />
		https://gitlab.com/2009scape/Saradomin-Launcher/-/archive/master/Saradomin-Launcher-master.zip?ref_type=heads<br />
	* Extract 2009scape-launcher to C:\2009scapeLauncher so that Saradomin.sln is in C:\2009scapeLauncher\Saradomin.sln<br />
	* Download Glitonea @ commit 9fb6de8<br />
		https://github.com/vddCore/Glitonea/archive/9fb6de8da53dbdde9d782ce4ab1c36c61d98ff71.zip<br />
	* Create a folder C:\2009scapeLauncher\Glitonea<br />
	* Extract Glitonea to C:\2009scapeLauncher\Glitonea so that Glitonea.csproj is in C:\2009scapeLauncher\Glitonea\Glitonea.csproj<br />
	* Navigate to C:\2009scapeLauncher and run Saradomin.sln with Visual Studio 2022<br />
	* Change settings from Debug to Release<br />
	* Navigate to Solution 'Saradomin' -> Saradomin -> Model -> Settings -> Client -> Double click on ClientSettings.cs<br />
	* Remove the servers that you're not going to play on. Keep TestServerAddress and LocalServerAddress<br />
	* Set TestServerAddress equal to your server's internal ip, be sure to enclose it in quotes. Don't use LocalServerAddress for intranet servers, only use it for localhost.<br />
		If doing this externally, obviously you would set it to your external ip or domain name.<br />
	* Save the file with ctrl s<br />
	* Press the green arrow that says "Start without debugging" to build and run it<br />
	
<br />
Getting In-Game:<br />
	* If you accidentally close the launcher, don't worry. You can reopen it by going to the build directory in C:\2009scapeLauncher\Saradomin\bin\Release\net6.0\<br />
	* Run Saradomin.exe and go to settings<br />
	* Enter your java executable location (java.exe)<br />
	* Select server profile: testing server<br />
	* Press play and create an account!<br />
	
<br />
Congratulations, you are finished!<br />
