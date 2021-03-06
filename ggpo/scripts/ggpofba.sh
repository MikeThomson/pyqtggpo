#!/bin/sh

# ggpofba wrapper script for version 0.2.96.74 (bundled with ggpo)
# (c)2013-2014 Pau Oliva Fora (@pof)
# (c)2014 papasi

# This resets pulseaudio on Linux because otherwise FBA hangs on my computer (WTF!?).
# For best results run 'winecfg' and check the option to "Emulate a virtual desktop"
# under the Graphics tab. I've it set to 1152x672 for best full screen aspect ratio.

# keep OSX happy:
cd "${0%/*}"

PARAM=${1+"$@"}

THIS_SCRIPT_PATH=`readlink -f $0`
THIS_SCRIPT_DIR=`dirname ${THIS_SCRIPT_PATH}`

FBA="./ggpofba"
if [ ! -x ${FBA} ] ; then
	FBA="${THIS_SCRIPT_DIR}/ggpofba"
fi
if [ ! -x ${FBA} ] ; then
	echo "Can't find ggpofba"
	exit 1
fi

if [ -x /usr/bin/xdg-mime ]; then
	# register fightcade:// url handler
	if [ ! -x ~/.local/share/applications/fightcade-quark.desktop ]; then
		echo "[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=FightCade Replay
Exec=${THIS_SCRIPT_DIR}/ggpofba.sh %U
Terminal=false
MimeType=x-scheme-handler/fightcade
" > ~/.local/share/applications/fightcade-quark.desktop
		xdg-mime default fightcade-quark.desktop x-scheme-handler/fightcade
	fi
fi
if [ -x /usr/bin/gconftool-2 ]; then
	gconftool-2 -t string -s /desktop/gnome/url-handlers/fightcade/command "${THIS_SCRIPT_DIR}/ggpofba.sh %s"
	gconftool-2 -s /desktop/gnome/url-handlers/fightcade/needs_terminal false -t bool
	gconftool-2 -t bool -s /desktop/gnome/url-handlers/fightcade/enabled true
fi

echo ${PARAM} |grep "^fightcade://challenge-.*@" >/dev/null
if [ $? -eq 0 ]; then
	quark=$(echo ${PARAM} |cut -f 1 -d "@" |cut -f 3 -d "/")
	game=$(echo ${PARAM} |cut -f 2 -d "@")
	PARAM="quark:stream,${game},${quark},7000 -w"
fi

if [ ! -x /usr/bin/pulseaudio ] || [ ! -x /usr/bin/pacmd ] || [ ! -x /usr/bin/pactl ]; then
	${FBA} ${PARAM} &
	exit 0
fi

# check if there's any application using audio
tot=$(/usr/bin/pacmd list-sink-inputs |grep ">>>.*sink input(s) available." |head -n 1 |awk '{print $2}')

# first instance resets pulseaudio, others don't
if [ ${tot} -eq 0 ]; then
	VOL=$(/usr/bin/pacmd dump |grep "^set-sink-volume" |tail -n 1 |awk '{print $3}')
	echo "-!- resetting pulseaudio"
	/usr/bin/pulseaudio -k
	/usr/bin/pulseaudio --start
fi

echo "-!- starting the real ggpofba"
${FBA} ${PARAM} &

if [ ${tot} -eq 0 ]; then
	sleep 1s
	echo "-!- restoring volume value"
	/usr/bin/pactl set-sink-volume 0 ${VOL}
fi
