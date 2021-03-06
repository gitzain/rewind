prefix=/usr
bindir=$(prefix)/bin
sharedir=$(prefix)/share
localedir=$(sharedir)/locale
launcherdir=$(sharedir)/applications
mandir=$(sharedir)/man
man1dir=$(mandir)/man1
CFLAGS=--std=c99
app_name=rewind
app_fullname=Rewind

all:
	#build binaries
	valac -X -D'GETTEXT_PACKAGE="${app_name}"' --Xcc="-lm" -X -Wl,-rpath,/usr/share/${app_name}/libs --thread "util/Misc.vala" "util/Logging.vala" "util/Devices.vala" "util/ProcessManagement.vala" "util/FileSystem.vala" "presentation/GtkHelper.vala" "util/Multimedia.vala" "util/JSON.vala" "util/System.vala" "presentation/MainWindow.vala" "presentation/SettingsWindow.vala" "presentation/RestoreWindow.vala" "presentation/ExcludeMessageWindow.vala" "logic/Rewind.vala" "presentation/SideBar.vala" "presentation/SideBarExpandableItem.vala" "presentation/HeaderBar.vala" "presentation/SnapshotsList.vala" "presentation/DriveList.vala" "presentation/DriveItem.vala"   -o ../bin/${app_name} --pkg glib-2.0 --pkg gio-unix-2.0 --pkg posix --pkg gtk+-3.0 --pkg gee-0.8 --pkg json-glib-1.0 --pkg gudev-1.0 --pkg granite
	
	#update translation template
	#xgettext --language=C --keyword=_ --copyright-holder='Zain Khan (emailzainkhan@gmail.com)' --package-name="${app_name}" --package-version='1.6' --msgid-bugs-address='emailzainkhan@gmail.com' --escape --sort-output -o ../${app_name}.pot *.vala
	rm -rf *.o ../bin/${app_name}

install:
	mkdir -p "$(DESTDIR)$(bindir)"
	mkdir -p "$(DESTDIR)$(sharedir)"
	mkdir -p "$(DESTDIR)$(mandir)"
	mkdir -p "$(DESTDIR)$(man1dir)"
	mkdir -p "$(DESTDIR)$(launcherdir)"
	mkdir -p "$(DESTDIR)$(sharedir)/${app_name}"
	mkdir -p "$(DESTDIR)$(sharedir)/pixmaps"
	mkdir -p "$(DESTDIR)$(localedir)/it_IT/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/ko_KR/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/fr_FR/LC_MESSAGES"
	
	#binary
	install -m 0755 ../bin/${app_name} "$(DESTDIR)$(bindir)"
	install -m 0755 ${app_name}-uninstall "$(DESTDIR)$(bindir)"
	install -m 0755 ${app_name}-launcher "$(DESTDIR)$(bindir)"
	
	#shared files
	cp -dpr --no-preserve=ownership -t "$(DESTDIR)$(sharedir)/${app_name}" ./share/${app_name}/*
	chmod --recursive 0755 $(DESTDIR)$(sharedir)/${app_name}/*
	
	#launcher
	install -m 0755 ../data/${app_name}.desktop "$(DESTDIR)$(launcherdir)"
	
	#app icon
	install -m 0755 ./share/pixmaps/${app_name}.png "$(DESTDIR)$(sharedir)/pixmaps/"
	
	#translations
	#msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/fr_FR/LC_MESSAGES/${app_name}.mo" ../po/${app_name}-fr.po
	
uninstall:

	#binary
	rm -f "$(DESTDIR)$(bindir)/${app_name}"
	rm -f "$(DESTDIR)$(bindir)/${app_name}-uninstall"
	rm -f "$(DESTDIR)$(bindir)/${app_name}-launcher"
	
	#shared files
	rm -rf "$(DESTDIR)$(sharedir)/${app_name}"
	
	#launcher
	rm -f "$(DESTDIR)$(launcherdir)/${app_name}.desktop"
	
	#app icon
	rm -f "$(DESTDIR)$(sharedir)/pixmaps/${app_name}.png"
	
	#translations
	rm -f $(DESTDIR)$(localedir)/*/LC_MESSAGES/${app_name}.mo
