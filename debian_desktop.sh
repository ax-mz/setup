#!/bin/bash

######## Debian Desktop

if [[ $XDG_SESSION_DESKTOP != "gnome" ]];
then
        echo "This script must run in Gnome environnement"
        exit 1
fi

if [[ $UID != 0 ]];
then
	echo "This script must be run as root"
	exit 1
fi

# Adding non-root user to sudoers 
user=$(grep ":1000:" /etc/passwd | cut -d: -f1)
echo -e "\n$user\tALL=(ALL:ALL) ALL" >> /etc/sudoers

# Add sublime-text repo
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
echo "deb https://download.sublimetext.com/ apt/stable/" > /etc/apt/sources.list.d/sublime-text.list

# Packages to install:
packages=(sudo bash-completion locate gnome-tweaks gnome-shell-extension-dashtodock git curl vlc keepassxc sublime-text)

apt -qq update && apt -qq upgrade -y
apt -qq install ${packages[@]} -y
apt -qq purge --autoremove gnome-games -y

##### Firefox config #####
if [ ! -d /home/$user/.mozilla/ ];
then
	su -c "firefox-esr --headless & sleep 1" $user
fi
pkill -15 firefox-esr
sed -i -e 's|^pref("browser.startup.homepage".*|pref("browser.startup.homepage",            "about:blank");|' /usr/share/firefox-esr/browser/defaults/preferences/firefox.js
sed -i -e 's|^pref("browser.urlbar.suggest.topsites".*|pref("browser.urlbar.suggest.topsites",             false);|' /usr/share/firefox-esr/browser/defaults/preferences/firefox.js
sed -i -e 's|^pref("browser.startup.page".*|pref("browser.startup.page",                0);|' /usr/share/firefox-esr/browser/defaults/preferences/firefox.js
sed -i -e 's|^pref("browser.download.manager.addToRecentDocs".*|pref("browser.download.manager.addToRecentDocs", false);|' /usr/share/firefox-esr/browser/defaults/preferences/firefox.js
sed -i -e 's|^pref("browser.download.useDownloadDir".*|pref("browser.download.useDownloadDir", false);|' /usr/share/firefox-esr/browser/defaults/preferences/firefox.js
sed -i -e 's|^pref("extensions.pocket.enabled".*|pref("extensions.pocket.enabled", false);|' /usr/share/firefox-esr/browser/defaults/preferences/firefox.js
sed -i -e 's|^pref("services.sync.prefs.sync.browser.urlbar.suggest.topsites".*|pref("services.sync.prefs.sync.browser.urlbar.suggest.topsites", false);|' /usr/share/firefox-esr/browser/defaults/preferences/firefox.js
sed -i -e 's|^pref("startup.homepage_welcome_url".*|pref("startup.homepage_welcome_url", "");|' /usr/share/firefox-esr/browser/defaults/preferences/firefox-branding.js
sed -i -e 's|^pref("browser.toolbars.bookmarks.visibility".*|pref("browser.toolbars.bookmarks.visibility", "always");|' /usr/share/firefox-esr/browser/defaults/preferences/firefox.js
sed -i -e 's|^pref("media.videocontrols.picture-in-picture.enabled".*|pref("media.videocontrols.picture-in-picture.enabled", false);|' /usr/share/firefox-esr/browser/defaults/preferences/firefox.js
sed -i -e 's|^pref("browser.sessionstore.resume_from_crash".*|pref("browser.sessionstore.resume_from_crash", false);|' /usr/share/firefox-esr/browser/defaults/preferences/firefox.js
sed -i -e 's|^pref("browser.sessionstore.restore_on_demand".*|pref("browser.sessionstore.restore_on_demand", false);|' /usr/share/firefox-esr/browser/defaults/preferences/firefox.js

## Install extensions
extensions=(ublock-origin i-dont-care-about-cookies)
prof_dir=$(ls /home/$user/.mozilla/firefox/ | grep "default-esr")
for ext in ${extensions[@]};
do
	xpi_url=$(curl -s https://addons.mozilla.org/fr/firefox/addon/$ext/ | sed 's/href=/\n/g' | sed 's|.xpi">|.xpi">\n|' | grep "firefox/downloads/file" | cut -d'"' -f2)
	xpi_name=$(echo $xpi_url | rev | cut -d/ -f1 | rev)
	wget -qP /home/$user/.mozilla/firefox/$prof_dir/extensions $xpi_url
	ext_id=$(unzip -p /home/$user/.mozilla/firefox/$prof_dir/extensions/$xpi_name manifest.json | grep -e '"id": ".*@.*"' | cut -d'"' -f4)
	mv /home/$user/.mozilla/firefox/$prof_dir/extensions/$xpi_name /home/$user/.mozilla/firefox/$prof_dir/extensions/$ext_id.xpi
done
chown -R $user:$user /home/$user/.mozilla/firefox/$prof_dir/extensions/

# automatic login
sed -i -e 's|^#  AutomaticLoginEnable.*|AutomaticLoginEnable = true|' /etc/gdm3/daemon.conf
sed -i -e "s|^#  AutomaticLogin .*|AutomaticLogin = $user|" /etc/gdm3/daemon.conf

# Aliases
echo -e "\n#Custon aliases: \nalias up='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'" >> /home/$user/.bashrc
echo "alias shutdown='systemctl poweroff'" >> /home/$user/.bashrc
echo "alias reboot='systemctl reboot'" >> /home/$user/.bashrc

##### Desktop config #####
# Wallpaper (replace command at the end of script)
wallpaper_url=https://raw.githubusercontent.com/ax-mz/setup/main/dune-2400x1408.jpg
wallpaper_name=$(echo $wallpaper_url | rev | cut -d/ -f1 | rev)
wget -q $wallpaper_url -P /usr/share/backgrounds/gnome/
# Window settings
su -c "gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'" $user
su -c "gsettings set org.gnome.nautilus.list-view default-visible-columns \"['name', 'size', 'date_modified']\"" $user
su -c "gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'" $user
# Gedit theme: cobalt
su -c "gsettings set org.gnome.gedit.preferences.editor scheme 'cobalt'" $user
## dash-to-dock
su -c "gsettings set org.gnome.shell enabled-extensions \"['dash-to-dock@micxgx.gmail.com']\"" $user
su -c "gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed 'true'" $user
su -c "gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'" $user
su -c "gsettings set org.gnome.shell.extensions.dash-to-dock extend-height 'true'" $user
su -c "gsettings set org.gnome.shell.extensions.dash-to-dock show-trash 'false'" $user
su -c "gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'" $user
su -c "gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink 'true'" $user
su -c "gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme 'true'" $user
su -c "gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size '26'" $user
su -c "gsettings set org.gnome.shell.extensions.dash-to-dock animate-show-apps 'false'" $user
# favorite-apps
su -c "gsettings set org.gnome.shell favorite-apps \"['org.gnome.Nautilus.desktop', 'firefox-esr.desktop','org.gnome.Terminal.desktop', 'org.keepassxc.KeePassXC.desktop', 'org.gnome.gedit.desktop', 'sublime_text.desktop', 'vlc.desktop', 'org.gnome.Screenshot.desktop']\"" $user

# Never lock screen
su -c "gsettings set org.gnome.desktop.session idle-delay '0'" $user
su -c "gsettings set org.gnome.desktop.screensaver lock-enabled 'false'" $user

su -c "gsettings set org.gnome.desktop.interface clock-show-weekday 'true'" $user

##### Terminal colors #####
# Red prompt for root
echo -e '\nPS1="${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /root/.bashrc
# Green prompt for user
sed -i -e 's|^#force_color.*|force_color_prompt=yes|' /home/$user/.bashrc
# colors for *grep
echo -e "\nalias grep='grep --color=auto'" >> /root/.bashrc
sed -i -e "s|^    #alias grep.*|    alias grep='grep --color=auto'|" /home/$user/.bashrc
sed -i -e "s|^    #alias fgrep.*|    alias fgrep='fgrep --color=auto'|" /home/$user/.bashrc
sed -i -e "s|^    #alias egrep.*|    alias egrep='fgrep --color=auto'|" /home/$user/.bashrc
## Themes
su -c "dconf write /org/gnome/terminal/legacy/profiles:/list \"['b1dcc9dd-5262-4d8d-a863-c897e6d979b9', '80067af7-16ba-4187-9e9c-826d8ac57e53']\"" $user
su -c "dconf write /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/visible-name \"'Original'\"" $user
su -c "dconf write /org/gnome/terminal/legacy/profiles:/:80067af7-16ba-4187-9e9c-826d8ac57e53/visible-name \"'Aci'\"" $user
# Aci (stolen from https://github.com/Gogh-Co/Gogh/blob/master/themes/Aci.yml)
su -c "dconf write /org/gnome/terminal/legacy/profiles:/:80067af7-16ba-4187-9e9c-826d8ac57e53/use-theme-colors 'false'" $user
su -c "dconf write /org/gnome/terminal/legacy/profiles:/default \"'80067af7-16ba-4187-9e9c-826d8ac57e53'\"" $user
su -c "dconf write /org/gnome/terminal/legacy/profiles:/:80067af7-16ba-4187-9e9c-826d8ac57e53/palette \"['rgb(54,54,54)', 'rgb(255,8,131)', 'rgb(131,255,8)', 'rgb(255,131,8)', 'rgb(8,131,255)', 'rgb(131,8,255)', 'rgb(8,255,131)', 'rgb(182,182,182)', 'rgb(66,66,66)', 'rgb(255,30,142)', 'rgb(142,255,30)', 'rgb(255,142,30)', 'rgb(30,142,255)', 'rgb(142,30,255)', 'rgb(30,255,142)', 'rgb(194,194,194)']\"" $user
su -c "dconf write /org/gnome/terminal/legacy/profiles:/:80067af7-16ba-4187-9e9c-826d8ac57e53/background-color \"'rgb(13,25,38)'\"" $user
su -c "dconf write /org/gnome/terminal/legacy/profiles:/:80067af7-16ba-4187-9e9c-826d8ac57e53/cursor-background-color \"'rgb(180,225,253)'\"" $user
su -c "dconf write /org/gnome/terminal/legacy/profiles:/:80067af7-16ba-4187-9e9c-826d8ac57e53/cursor-foreground-color \"'rgb(194,253,180)'\"" $user
su -c "dconf write /org/gnome/terminal/legacy/profiles:/:80067af7-16ba-4187-9e9c-826d8ac57e53/foreground-color \"'rgb(180,225,253)'\"" $user
su -c "gsettings set org.gnome.Terminal.Legacy.Settings theme-variant 'dark'" $user

# replace wallpaper
su -c "gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/gnome/$wallpaper_name'" $user

systemctl reboot
