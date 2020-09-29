# About:
HockeyKit comprises two separate useful elements:
* An Android and iOS Ad-Hoc hosting system.
* A native client library for Android and iOS that automatically (or manually) can phone home to the server and notify of updates.

# Why use it?
* Compared to the alternatives, I think it improves the usability for beta testers dramatically.    
  * TestFlight is very slow to update and cannot be used without requiring beta testers to install Test Flight.  I've also seen a lot of failures uploading to Test Flight that are simply Apple's servers failing to be reached or giving up part-way through for one reason or another.  
  * Microsoft's AppCenter.ms is better.  Technically, it's a more mature version of this software, but it's also a convoluted mess of permissions.  It also handles iOS and Android apps with the same bundle ID very poorly.  
* This implementation is a simple, tight docker container for hosting builds, that you can actually run yourself.  Rather than deal with slow uploading to a 3rd party, and slow downloading, you can host this on-premises or on your own AWS instance or wherever.  Super easy.

# How does it work?
* The server component is required for all scenarios, but it can work standalone without integrating the client library at all.
* Multiple apps can be served from a single running server instance.  It is strongly recommended to use three different bundle names for different kinds of builds, as it prevents mistakes on release. For example: 
  * com.company.appname.debug
  * com.company.appname.beta
  * com.company.appname.release

## Server
* Packed up as a Docker image with Nginx, PHP 7, and Alpine for a really small memory footprint and high performance.
* Simply mount a volume at /hockey_data/ that will contain all your app versions, so it survives container restarts.
* All traffic happens over port 8000.
* Build with this command:  `docker build . -t hockeykit:latest`
* Run with this command: `docker run -d --rm --name hockeykit -e AUTH_SECRET=somepassword -v /your/folder:/hockey_data -p 8000:8000 hockeykit:latest`
* **Security** Strongly advised to put this behind an oauth2-proxy container, along with cert-bot, so you always serve over HTTPS and only after you've authenticated externally.


## Android
Android is relatively simple to allow installs, but depends on the device.  To enable Developer Mode (may not be necessary): On vanilla Google Android, simply go to Settings->About Phone and **tap 7 times** on Build Number.

Search for your device an find where "Allowing app installs from Unknown Sources" is in your Settings menu.  Google has it under Settings->Apps->Advanced->Special App Access->Install Unknown Apps.  Once here, you can enable the permission for specific apps to allow them to install.  Chrome should be enabled, at least, and if your app is capable of updating itself, enable it here as well.  Samsung users will need to go through slightly different menus, as described here https://www.verizon.com/support/knowledge-base-222186/  If this doesn't seem to work, search for "Allowing app installs from Unknown Sources". 

Once you have given your phone permission to do dangerous things, you can generally download and install .apk's directly from your browser.

## iOS
The administrator has to copy the AdHoc provisioning profile to the hosting folder.  This includes the UDID numbers for all the devices that are allowed to install each app.

One server installation is able to  handle multiple applications via different bundle identifiers (I highly suggest using different bundle identifiers for Debug, AdHoc Beta and AppStore release builds !!!).
By default the client library will check for updates on your server whenever the app is started or will wake up. The user can adjust this in the settings dialog to alternatively only check once a day or manually.

This framework was created after reading the blog post at http://jeffreysambells.com/posts/2010/06/22/ios-wireless-app-distribution/ where Jeffrey Sambells wrote about the mechanisms required and being available for us to use.

A complete documentation can be found in the wiki at https://github.com/TheRealKerni/HockeyKit/wiki

# Requirements:
- iOS 7.1 and later require apps to be distributed via https using a valid signed server certificate trusted by the iOS device

# Features:
- iOS AdHoc build OTA distribution
- Automatically generated website, in specific versions for all device types and desktop browser
- Web interface only requires subdirectory to be created and and .ipa and .plist file (any name) being added/updated
- Website can be used for first time installation and updates, iOS3 users can use the website from a desktop browser to download the app, iTunes installation instructions for those are also included
- Can handle multiple apps on one server, one subdirectory per app
- Optionally shows release notes by displaying the content of a file with the extension .html (use HTML format without wrapping it in <html> and <body>)
- Provisioning profile link shown optionally (useful if new users are added without building a new version just for them)
- Support for app icon on website and during installation on the device, place any .png file into the subdirectory (114x114 pixel works on all devices!)
- Optional client side framework
- Framework notifies users on startup of new updates, iOS4 users can install directly from within the client (In-App-Updates), iOS3 users will be hinted to the website
- Framework optionally sends UDID, app version, iOS version, device type to the server, overview will appear automatically in /stats/ website (write access for PHP scripts required)
- Stats website supports replacing UDIDs with names by entering them into a userlist.txt file within the stats subdirectory
- Bookmarklet to extract all UDIDs and names from iOS program portal device page available in the stats page
- Template for an Xcode 3 build script to upload all files to your server after a build (Beta Automatisation.sh)


# Notes:
- The server can run stand alone, the client is optional
- Beta testers need to run at least iOS 4 to benefit from the auto update functionality
- Beta testers using iOS 3 will also be notified of updates within the app
- Please check the iOS README.md for addition iOS client related notes
- Do not enter a link to the app icon in the organizer screen. Hockey will add that part into the PList automatically on the server, if there is a PNG file found (114pixel icons work on all devices!)
- Make sure the IPA filename has no space in it. iOS is not able to call that URL correctly.
- Don't make separate names per IPA file you make, because only the first file found per directory be served


# How to add a new iOS application version (Xcode 3):
* Create a subdirectory with the bundle identifier string as the name on the server (if it does not exist yet)
* Copy the provisioning profile into that subdirectory, it is important to have the extension ".mobileprovision" (mandatory file)
* Start XCode
* Invoke "Build and Archive"
* Open the Organizer
* Choose "Archived Applications"
* Select the build you want to publish
* Select "Share application"
* Select "Distribute for Enterprise..."
* Fill out the URL field and type "__URL__" (important !!)
* Enter a title, this will be shown in the web interface and on the client
* Version number will be taken automatically from the generated plist file
* Note: The client does not check if the version number is actually a bigger number, it only checks if they are different, which should be fine anyway
* Save it, two files will be saved, one .plist and one .ipa
* Upload the plist file into the subdirectory on the server, it is important to have the extension ".plist" (mandatory)
* Upload the application file into the subdirectory on the server, it is important to have the extension ".ipa" (mandatory)
* If you don't want this application to appear in the web interface, add a file named "private" (optional)
* If you want to add release information to the web interface and the client, add a file with the extension ".html" which contains the release information as HTML (without header and body)
* Note: If one of the mandatory files do not exist in the directory, the update or installation will not be made available


# Acknowledgments:

The following 3rd party open source libraries have been used:

* JSONKit by johnezang (https://github.com/johnezang/JSONKit)
* SBJson by Stig Brautaset (http://github.com/stig/json-framework)
* PSStoreButton by Peter Steinberger (https://github.com/steipete/PSStoreButton)
* NSString+URLEncoding by Kaboomerang LLC.
* blueprint css framework (http://blueprintcss.org/)
* PHP plist reader code from http://blog.iconara.net/2007/05/08/php-plist-parsing/
