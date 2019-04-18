#!/bin/bash
# 
# This file is part of breakout.sh
# Copyright (c) 2014 Amos Brocco.
# 
# This program is free software: you can redistribute it and/or modify  
# it under the terms of the GNU General Public License as published by  
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
MINX=1
MAXX=80
MINY=2
MAXY=24
CRACCHETTA="\u2680"
LRACCHETTA=5
BACKGROUND=" "
PALLINA="\u2688"

pallinaX=0
pallinaY=$MINY
pallinaDirX=1
pallinaDirY=1
racchettaX=40
racchettaY=20
direzione=1
fineGioco=0
punteggio=0
palline=3

pallinaX=$RANDOM
let "pallinaX %= $MAXX"

stty -echo # Disabilita echo dei tasti

# Muove il cursore alla coordinata X Y
function muovi_cursore
{
	echo -en "\033[$2;$1f"
}

# Crea un mattoncino di colore C alla posizione X Y
function crea_mattoncino()
{
	mattoncino="$1:$2:$3"
	mattoncini="$mattoncini $mattoncino"
}

function distruggi_mattoncino()
{
	mattoncini=$(echo $mattoncini | sed -e "s/\s$1:$2:\w\s/ /")
	muovi_cursore $1 $2
	echo -en "\033[0;0m"
	echo -en "$BACKGROUND"
	punteggio=$(($punteggio + 10))
}

function rileva_collisioni()
{
	# Calcola nuova posizione
	newX=$(expr $pallinaX + $pallinaDirX)
	newY=$(expr $pallinaY + $pallinaDirY)
	upy=$(expr $newY)
	downy=$(expr $newY)
	leftx=$(expr $newX)
	rightx=$(expr $newX)

	if [ $leftx -le $MINX ]; then
		# Test bordo sinistra
		pallinaDirX=$(($pallinaDirX * -1))
	elif [ $rightx -ge $MAXX ]; then
		# Test bordo destra
		pallinaDirX=$((pallinaDirX * -1))
	elif echo $mattoncini | grep -qE "\s$leftx:$pallinaY:\w"; then
		# Mattoncino colpito da destra
		distruggi_mattoncino $leftx $pallinaY "r"
		pallinaDirX=$(($pallinaDirX * -1))
	elif echo $mattoncini | grep -qE "\s$rightx:$pallinaY:\w"; then
		# Mattoncino colpito da sinistra
		distruggi_mattoncino $rightx $pallinaY "l"
		pallinaDirX=$(($pallinaDirX * -1))
	fi

	if [ $upy -lt $MINY ]; then
		# Test bordo sopra
		pallinaDirY=$(($pallinaDirY * -1))
	elif [ $downy -ge $MAXY ]; then
		# Test sotto
		return 1	# Fine gioco
	elif echo $mattoncini | grep -qE "\s$pallinaX:$upy:\w"; then
		# Mattoncino colpito da sotto
		distruggi_mattoncino $pallinaX $upy "d"
		pallinaDirY=$(($pallinaDirY * -1))
	elif echo $mattoncini | grep -qE "\s$pallinaX:$downy:\w"; then
		# Mattoncino colpito da sopra
		distruggi_mattoncino $pallinaX $downy "u"
		pallinaDirY=$(($pallinaDirY * -1))
	fi
	
	if [ $newY -eq $racchettaY -o $pallinaY -eq $racchettaY ]; then
		if [ $newX -ge $racchettaX -a $newX -le $(expr $racchettaX + $LRACCHETTA) ]; then
			pallinaDirY=$(($pallinaDirY * -1))
			if [[ $pallinaDirX -ne $direzione ]]; then
				pallinaDirX=$(($pallinaDirX * -1))
			fi
		fi
	fi	
}

function cambia_colore()
{
	case $1 in
		R) echo -en "\033[0;31m" ;;
		G) echo -en "\033[1;32m" ;;
		B) echo -en "\033[1;34m" ;;
		*) echo -en "\033[0;0m" ;;
	esac
}

function cancella_pallina()
{
	muovi_cursore $pallinaX $pallinaY
	echo -en "\033[0;0m"
	echo -en "$BACKGROUND"	
}

function aggiorna_pallina()
{
	# Aggiorna posizione pallina
	pallinaX=$(expr $pallinaX + $pallinaDirX)
	pallinaY=$(expr $pallinaY + $pallinaDirY)
}

function disegna_pallina()
{
	muovi_cursore $pallinaX $pallinaY
	echo -en "$PALLINA"
	muovi_cursore $MAXX $MAXY
}

function cancella_racchetta()
{
	muovi_cursore $racchettaX $racchettaY
	for i in $(seq 1 $LRACCHETTA); do
		echo -en "$BACKGROUND"
	done
}

function aggiorna_racchetta()
{
	cancella_racchetta
	LIMITERAC=$(expr $MAXX - $LRACCHETTA)
	LIMITERACMIN=$(expr $MINX + 1)
	racchettaX=$(($racchettaX + $1))
	if [ $racchettaX -lt $LIMITERACMIN ]; then
		racchettaX=$LIMITERACMIN
	elif [ $racchettaX -gt $LIMITERAC ]; then
		racchettaX=$LIMITERAC
	fi
	disegna_racchetta
}

function disegna_racchetta()
{
	muovi_cursore $racchettaX $racchettaY
	echo -en "\033[0;0m"
	for i in $(seq 1 $LRACCHETTA); do
	echo -en "$CRACCHETTA"
	done
}
	
function disegna_schema()
{
	# Disegna i mattoncini
	for m in $mattoncini; do
		x=$(echo $m | cut -d':' -f1)
		y=$(echo $m | cut -d':' -f2)
		colore=$(echo $m | cut -d':' -f3)
		cambia_colore $colore
		muovi_cursore $x $y
		echo -e "\u2610"
	done
}			

function disegna_sfondo() 
{
	clear
	echo -en "\033[0;0m"
	for x in $(seq $MAXX -1 1); do
		for y in $(seq 1 $MAXY); do
			muovi_cursore $x $y
			echo -en "$BACKGROUND"
		done
	done
}

function leggi_schema()
{
	if [ -f "$1.cache" ]; then
		mattoncini=$(cat $1.cache)
	else
		x=0
		y=0
		while read -s -n1 c; do
			x=$(expr $x + 1) # incrementa x
			if [ -z "$c" ]; then
				y=$(expr $y + 1) # incrementa y
				x=0	# reset di x
				continue
			elif [ "$c" != "#" ]; then
				crea_mattoncino $x $y $c
			fi
		done < $1
		echo $mattoncini > $1.cache
	fi
}

function pulisci_stato()
{
	for (( i=2; i<79; i++ )) {
		muovi_cursore $i $(expr $MAXY - 1)
		echo -en "\033[0;0m"
		echo " "
	}
}


function scrivi_messaggio()
{
	muovi_cursore 3 $(expr $MAXY - 1)
	echo -en "\033[0;0m"
	echo "$1"
}

function disegna_stato()
{
	echo -en "\033[0;0m"
	scrivi_messaggio "Punteggio: $punteggio    Palline rimaste: $palline  [A sinistra, D destra]"
}

function disegna_frame()
{
	for (( i=1; i<24; i++)) {
		muovi_cursore 80 $i
		echo -e "\u2551"
	}
	for (( i=1; i<24; i++)) {
		muovi_cursore 0 $i
		echo -e "\u2551"
	}
	for (( i=1; i<80; i++)) {
		muovi_cursore $i 0
		echo -e "\u2550"
	}
	for (( i=1; i<80; i++)) {
		muovi_cursore $i 24
		echo -e "\u2550"
	}		
	muovi_cursore 1 1
	echo -e "\u2554"
	muovi_cursore 1 24
	echo -e "\u255A"	
	muovi_cursore 80 1
	echo -e "\u2557"
	muovi_cursore 80 24
	echo -e "\u255D"		
}

function attesa() {
	pulisci_stato
	scrivi_messaggio "Pronto?    "
	sleep 2
	pulisci_stato
	scrivi_messaggio "Partenza..."
	sleep 2
	pulisci_stato
	scrivi_messaggio "Via!"
	sleep 1
	pulisci_stato
}

function loop_gioco()
{
	delay=1
	disegna_racchetta
	disegna_pallina
	disegna_frame
	attesa
	while [ $fineGioco -ne 1 ]; do
		if [ $delay -eq 0 ]; then
			cancella_pallina
			aggiorna_pallina
			disegna_pallina
			if ! rileva_collisioni; then
				palline=$((palline - 1))
				if [ $palline -gt 0 ]; then
					pulisci_stato
					scrivi_messaggio "Peccato!"
					sleep 2
					attesa
					cancella_pallina
					pallinaX=$RANDOM
					let "pallinaX %= $MAXX"
					pallinaY=$MINY
					pallinaDirX=1
					pallinaDirY=1
					disegna_pallina
				else
					pulisci_stato
					scrivi_messaggio "Hai perso!"
					exit 0;
				fi
			fi
			disegna_stato
			delay=3
		fi
		#sleep 0.001
		direzione=$pallinaDirX
		if read -s -n1 -t0.1 tasto; then
			case $tasto in
				a) aggiorna_racchetta -3; direzione=-1;;
				d) aggiorna_racchetta 3; direzione=1;;
				q) exit 0;;
			esac
		fi
		delay=$(($delay -1))
	done
}

leggi_schema schema1
disegna_sfondo
disegna_schema
loop_gioco


