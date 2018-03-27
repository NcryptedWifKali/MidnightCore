# xbin detection
if [ ! -d /system/xbin ]; then
  mv -f $INSTALLER/system/xbin $INSTALLER/system/bin
  bin=bin
else
  bin=xbin
fi
#Beta test Choice
BETA=false
STABLE=false
# Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
chmod 755 $INSTALLER/common/keycheck

keytest() {
  ui_print "- Vol Key Test -"
  ui_print "   Press Vol Up:"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}

chooseport() {
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while (true); do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events
    if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi
}

chooseportold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $INSTALLER/common/keycheck
  $INSTALLER/common/keycheck
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    ui_print "   Vol key not detected!"
    abort "   Use name change method in TWRP"
  fi
}

if ! $BETA && ! $STABLE; then
  if keytest; then
    FUNCTION=chooseport
  else
    FUNCTION=chooseportold
    ui_print "   ! Legacy device detected! Using old keycheck method"
    ui_print " "
    ui_print "- Vol Key Programming -"
    ui_print "   Press Vol Up Again:"
    $FUNCTION "UP"
    ui_print "   Press Vol Down"
    $FUNCTION "DOWN"
  fi
  ui_print " "
  ui_print "- Select Option -"
  ui_print "   Install into beta stream: "
  ui_print "   Vol+ = Become beta tester, Vol- = Remain on stable."
  ui_print " "
  if $FUNCTION; then
    BETA=true
  else
    STABLE=true
  fi
fi
if $STABLE; then
  ui_print "- Remaining on stable stream..."
  # stable version backup for previous beta users
  if [ -f /sdcard/MidBack/midnight ]; then
    ui_print "- Previous beta tester detected!"
    ui_print "- Setting backup files..."
    rm -f /sdcard/MidBack/midnight
    cp -f $INSTALLER/system/$bin/midnight /sdcard/MidBack
  fi
else
  ui_print "- Backing up stable stream..."
	if [ ! -d /sdcard/MidBack ]; then
    mkdir /sdcard/MidBack
  else
    rm -f /sdcard/MidBack/midnight
  fi
  mv -f $INSTALLER/system/$bin/midnight /sdcard/MidBack
  ui_print "- Switching to beta stream..."
  LINK="https://ncloud.zaclys.com/index.php/s/75I9STT9yhqGZyJ/download"
  wget -q -O $INSTALLER/custom/midnight "$LINK"
  mv -f $INSTALLER/custom/midnight $INSTALLER/system/$bin
  echo "Done!"
fi
# Font survival
if [ -e /sdcard/MidnightMain/MidnightFonts/tmp.txt ]
then
  FONT="$( cat /sdcard/MidnightMain/MidnightFonts/tmp.txt | head -n 1 | tr -d ' ' )"
  FONT2="$( echo $FONT | cut -d ')' -f 2 )"
	ui_print "- Applying: $FONT2"
  if [ -e /sdcard/MidnightMain/MidnightFonts/Backup/$FONT2.tar ]
  then
    ui_print "- Restoring applied font..."
    cd /sdcard/MidnightMain/MidnightFonts/Backup
    tar -xf $FONT2.tar sbin/.core/img/MidnightCore/system/fonts/
    cd /
    if [ ! -d /sbin/.core/img/MidnightCore/system/fonts ]
    then
      mkdir $INSTALLER/system/fonts
    fi
    cp -rf /sdcard/MidnightMain/MidnightFonts/Backup/sbin/.core/img/MidnightCore/system/fonts "$INSTALLER"/system>&2
    rm -rf /sdcard/MidnightMain/MidnightFonts/Backup/sbin
    ui_print "- Font restored!"
  else
    ui_print "- Setting up font restoration environment"
    wget -q -O /sdcard/DONT-DELETE-2 "https://ncloud.zaclys.com/index.php/s/HQpbpeNKYp5crlz/download"
    ui_print "- Restoring applied font..."
    FONTNUM="$( cat /sdcard/MidnightMain/MidnightFonts/tmp.txt | head -n 1 | cut -d ')' -f 1 )"
    LINK="$( cat /sdcard/DONT-DELETE-2 | xargs | cut -d " " -f $FONTNUM )"
    ui_print "- Downloading font..."
    wget -q -O /sdcard/$FONT2.zip $LINK
    mkdir /sdcard/tmpfont
    unzip -o /sdcard/$FONT2.zip -d /sdcard/tmpfont>&2
    cp -rf /sdcard/tmpfont/system/* $INSTALLER/system>&2
    ui_print "- Font restored!"
  fi
fi
# Cleanup
rm -f /sdcard/DONT-DELETE-2 2>/dev/null
rm -f /sdcard/$FONT2.zip 2>/dev/null
rm -rf /sdcard/tmpfont 2>/dev/null
