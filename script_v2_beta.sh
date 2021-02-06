#!/bin/bash 

# This is function I used to keep log instead of echo since you can comment the line #1 in the function and there would be no log
# This is easier than editing every other echo and removing it sometimes.
log()
{ 
	echo $1
}
#set -- "list"
#This function removes some frames depending on total size of resultant png
#If it's more than 700kb (look at "workplz") then $1 is 1 , and frames removed are 
# 		a=(2 5 7 8 11 13 14 17 20 22 26 30)
#After it removes those frames It reorders files in order
#For example
#Files : 
# filepng01.png
# filepng02.png
# filepng03.png
# 
# You removed 2nd file , Now files become
# filepng01.png
# filepng03.png
#
#apnggasm doesn't work for files not in sequence as here , Hence this function ensures it's in sequence
#after removing filepng02, it makes filepng03 become filepng02.
remove()
{
	ref=("00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30")
	a=(1)
	if [ $1 -eq "1" ]
	then
		a=(2 5 7 8 11 13 14 17 20 22 26 30)
	elif [ $1 -eq "2" ]
	then
	        a=(1 3 7 11 13 17 20 24 29)
	elif [ $1 -eq "3" ]
	then
		a=(3 9 12 15 20 24)
	elif [ $1 -eq "4" ]
	then
		a=(4 8 12 14)
	else
		a=(5 10)
	fi
#	log $1
	let "val=1"
  for file in ./filepng*.png
	do
        for i in $a
        do
	         #  log "checking $file with index $i at index $val"
	           if [ $val -eq $i ]
	           then
						#	 log "removing file $file"
			          rm $file 
			       break 
	           fi
        done
        let "val=$val+1"
  done
	let "count=1"
	for file in ./filepng*.png 
	do
		newfname="./filepng${ref[$count]}.png"
		let "count=$count+1"
		#log "Comparing $file against newname $newfname"
		if [[ "$newfname" == "$file" ]];
		then 
			continue
		else
#			log "Moving $file to $newfname"
			mv $file $newfname
		fi 
  done 
}



# Depending on file size decide how many frames to drop and call "remove" for it
# Then collect all pngs left after dropping frames to create new file and check for it's size.
# if it's <300 kb then it's alright!!!!!
# otherwise redo the process again :"(
FILE_I=$1 
workplz()
{
	a=$(du "$1" | sed -e "s/\s.*png//")
	if [ $a -gt "700" ]
	then
		remove 1
	elif [ $a -gt "600" ]
	then
		remove 2
	elif [ $a -gt "500" ]
	then
		remove 3
	elif [ $a -gt "400" ]
	then
		remove 4
	elif [ $a -gt "300" ]
	then
		remove 5
	else
	#	echo "$1 already at best"
		if [[ ! -f tmp.png ]];
		then
			mv $1 tmp.png 
		fi
		return
	fi
	if [[ -f tmp.png ]];
	then
	  rm tmp.png  
	fi 
	apngasm tmp.png $(ls filepng* | tr '\n' ' ') -z0 > /dev/null 
        workplz tmp.png 
}

INPUU=""
NOTIFY="NO"
IN_BACKUP="0"
TOTALF="0"
FILE_I=""
let "COUNTER=0"
 if [[ "$(tty)" == "not a tty" ]] ;
 then 
      NOTIFY=""
 fi 

info () {
 if [[ "$NOTIFY" == "" ]];
 then 
	 if [[ "$2" == "" ]];
	 then
		 notify-send "$1"
	 else
		 zenity --info --text="$1" --width="400"
	 fi
 else
	 echo "$1"
 fi
}
trap "echo exitting because my child killed me.>&2;exit" SIGUSR1
installbak() {
a=$(cat .back)
SAVEIFS=$IFS   # Save current IFS
IFS=$'\n'      # Change IFS to new line
a=($a)
ee=$$
if [[ "$NOTIFY" == "" ]]
then
 (
  TOTx=$(cat .back | wc -l )
	count=1
	for i in "${a[@]}" 
	do 
      cp -f .backup/$i/pack pack
		  cp -rf .backup/$i/output output
		  cp -r .backup/$i/emoji emoji 
			echo "# Uploading ($count/$TOTx) $(cat pack)"
			echo $(( count * 100 / TOTx ))
		  if python3 bot.py 2> /dev/null 
		  then
			  log "# Pack $i $(cat pack) uploaded"
			  sed "/^$i$/d" .back > .lss 
				mv .lss .back 
				rm -rf .backup/$i
      else
				killall zenity 
			  info " Please check network connection!!!" 1
				kill $ee 
				kill $$
		  fi
			let "count=$count+1"
	 done 
	 echo 100
  ) | zenity --progress \
				--title="Converting($conv/$TOT) $iii " \
      --text="Downloading...." \
      --percentage=0 \
      --auto-close \
      --auto-kill \
	    --width=500 
else
	 for i in "${a[@]}" 
   do
      cp -f .backup/$i/pack pack
		  cp -rf .backup/$i/output output
		  cp -r .backup/$i/emoji emoji 

		  if python3 bot.py 2> /dev/null
		  then
			  log "Pack $i $(cat pack) uploaded"
			  sed "/^$i$/d" .back > .lss
				mv .lss .back 
      else
			  info "Please check network connection!!!" 1
			exit 1
		  fi
		  rm -rf .backup/$i
		done 
	fi
echo "-------"
info "All backups have been uploaded !!! Continuing?" 1 
echo "-------"
echo -n "" > pack 
echo -n "" > emoji
rm -rf output 
}

post () {
#	notify-send "In post with $1 and $(tty)"
if [[ "$NOTIFY" == "" ]] ;
then
		if [ ! -f /usr/bin/zenity ] ;
		then
			notify-send "Please install zenity"
			exit 1
		fi
		INPUU=$(zenity --entry --title="Sticker Pack Creator <3" --text="$1")
		if [[ "$INPUU" == "" ]] ;
		then
			notify-send "Script cancelled"
			exit 
		fi 
else
		printf "$1\n"
		read INPUU
fi
}
#Output comes here 
#install dep
depi () {
	if [ -f /usr/bin/apt ]
	then 
		log "Installing $1 for ubuntu"
		if sudo apt install $1  ; 
		then
			log "installed" 
		else
			exit 
		fi 
	elif [ -f /usr/bin/pacman ] ;
	then
		log "Installing $1 for arch" 
     if sudo pacman -S $1  ; 
		then
			log "installed" 
		else
			exit 
		fi
	else
		log "Install $1 manually for now"
	fi
}


#Check and ask to install dep 
installdep () {
	if [ -f /usr/bin/apngasm ] ;
	then
		log "apngasm is installed !!!!!!!!!!!!!"
	else
		log "Trying to install apnggasm"
		depi apngasm  
	fi 
  
	if [ -f /usr/bin/gifsicle ] ;
	then
		log "Gifsicle is installed !!!!!!!!!!!!"
	else
		log "Trying to install gifsicle"
		depi gifsicle 
	fi 

	if [ -f /usr/bin/convert ] ;
	then
		log "Imagemagick is installed !!!!!!!!"
	else
		log "Imagemagick is not installed, Trying to install it"
		depi imagemagick 
	fi 
		
	if [ -f /usr/bin/tgs-to-gif ] ;
	then
		log "tgs-to-gif is installed !!!!!"
	else 
		log "Not installed tgs to gif , Need to  take help of github here " 
    log "visit https://github.com/ed-asriyan/tgs-to-gif/tree/master-cpp" 
	  exit 1 
	fi 

} 
dobackup() {
	if [[ ! -d .backup ]];
	then
		mkdir .backup 
	fi 
	if [[ ! -f .back ]];
	then
		touch .back
	fi 
	for i in {0..100..1}
	do 
		if [[ -d .backup/$i ]];
		then
			continue
		fi 
    mkdir .backup/$i 
	  echo $i >> .back 
		cp -rf output .backup/$i/ 
		cp emoji .backup/$i/
		cp pack .backup/$i/ 
		log "Couldn't Upload hence backup created in folder .output/$i , rerun script to do Upload"
		break
	done 
}

maininstall() {
TOTALF=$(ls *.tgs | wc -l )
if [[ ! -d ./output ]]
then
   mkdir output 
fi 
log "---------"
log "Total Files $TOTALF"

for file in ./*.tgs 
do
	finalfilename=$(echo $file | sed -e "s/\.tgs/\.png/g" | sed -e "s/^\.\///g" ) 
	tgs-to-gif -f 30 $file 
	file="$file.gif"
	counter=1
	total=$(identify $file | wc -l )
	let "counter=$total/30"
	let "counter=$counter+1"
        if [ $counter -gt "7" ]
	then
		echo "# You will be suffering here but I am continuing"
	fi
	#Running loop to find average frame delay , just for better working case
	let "total=$total-1"
	totalloop=0
	
	for i in {0..$total..1}
	do
		looptime=$(identify $file  | grep "\[$i\]" | sed "s/^.*\.//g")
		let "totalloop=$looptime+$totalloop"
	done

	let "total=$total+1"
        let "totalloop=$totalloop*$counter"
	let "totalloop=$totalloop/$total"
	if [[ -f output.gif ]];
	then
	   rm output.gif
	fi 
	log "----------------------"
	printf "Avg Frame Delay = $totalloop \n Total Frame = $total \n Dividing total frame by = $counter \n Working on  = $file \n"
	log "# Converting gif !--! $file"
	gifsicle -U $file  -d $totalloop  `seq -f "#%g" 0 $counter $total` -O9 --colors 255  -o output.gif  >/dev/null  2>&1
	
	file1=output.gif
	convert -compress LZW   -coalesce $file1  filepng%02d.png
	newf=$(echo $file1 | sed -e "s/\.gif/\.png/g" ) 
	
	echo "# Making apng of $file"
	apngasm $newf filepng*  > /dev/null 
	workplz $newf 
	mv tmp.png ./output/$finalfilename
	rm filepng*
	let "COUNTER=$COUNTER+1"
	if [[ "$NOTIFY" == "" ]];
	then
		  echo $(( COUNTER * 100 / TOTALF ))
	fi 
done
rm *.tgs 
rm *.gif
#rm *.png 
echo "Time to upload pack, conversion has been done!!!!"

if python3 bot.py 2> /dev/null 
then
	info  "Pack uploaded $(cat pack)"
else
	info "Pack wasn't uploaded Doing backup !! "
  dobackup
  #cat pack >> not_uploaded
fi
echo "Cleaning up"
rm -rf output
}

dosingle() {
      if python3 download.py 2> /dev/null 
	    then
         maininstall
		  else
				info "Can't download pack $(cat pack)"
			   cat pack >> not_uploaded 
		  fi
}

installdep
#Collect all tgs files in directory
if [[  -s .back ]];
then
  if [[ "$NOTIFY" == "" ]] ;
  then
       if zenity --question --text "Backup file found, Do you want to upload those stickers which are left out?" --width=400 --title="Sticker Pack Creator <3" 
			 then
            installbak 
       fi
	else
		echo  "Backup file found, Do you want to upload those stickers which are left out? (N/y)"
    read xxx 
		if [[ "$xxx" == "y" ]];
		then 
		   installbak
		elif [[ "$xxx" == "Y" ]];
		then
			installbak
		else
			log "Skipped backup"
		fi
	fi
fi

rm pack > /dev/null 2>&1
if [ -f token ] ;
then
	log "Token found continuing"
else
	post "Telegram Bot Token not found, \n Please use v1 if you have tgs , \n v2 always downloads tgs requires bot token \n 
 You can input token now or exit"
	echo $INPUU > token
	post "Enter author's name"
	echo $INPUU >> token
	post "Now open Signal Desktop ,\n Goto Menu -> Toggle Developers tools -> On there open Console \n Paste output of window.reduxStore.getState().items.uuid_id" 
	echo $INPUU >> token
	post  "You are almost there \n Paste output of window.reduxStore.getState().items.password"
	echo $INPUU >> token
fi

takein() {
	if [[ "$NOTIFY" == "" ]]
	then
		INPUU=$(zenity --text="Enter" --entry  --ok-label="Convert this" --extra-button="Choose file")
		if [[ "$INPUU" == "Choose file" ]]
		then
		   INPUU=$(zenity --file-selection )
			 FILE_I=$INPUU 
		fi 
		if [[ "$INPUU" == "" ]]
		then
			notify-send "Cancelling conversion"
			exit 1
		fi 
	else
		###
		if [[ "$1" == "" ]]
		then 
		  post "Please input link to pack to be converted eg https://t.me/addstickers/HalloUtya" 
      echo  $INPUU > pack
		fi
	fi 
	  
}
FILE_I=$1 
takein $1  
if [[ "$FILE_I" == "" ]] ;
then
	if [[ "$NOTIFY" == "" ]]
	then
		(
	    dosingle 
		) | zenity --progress \
  --title="Cooking APNG's" \
  --text="Downloading...." \
  --percentage=0 \
  --auto-close \
  --auto-kill \
	--width=500 
		else
		   dosingle 
  	fi
else
     TOT=$(cat $FILE_I | wc -l )
		 conv=1 
	   aaaa=$(cat $FILE_I)
     SAVEIFS=$IFS   # Save current IFS
     IFS=$'\n'      # Change IFS to new line
     aaaa=($aaaa)
		 IFS=$SAVEIFS
		 # split to array $names
     for iii in "${aaaa[@]}"
     do 
       echo "# Installing" $iii
       echo  "$iii" > pack
	  if [[ "$NOTIFY" == "" ]]
		then
			(
			 dosingle 
		  ) | zenity --progress \
				--title="Converting($conv/$TOT) $iii " \
      --text="Downloading...." \
      --percentage=0 \
      --auto-close \
      --auto-kill \
	    --width=500 
		 else
		    dosingle 
		 fi
		 let "conv=$conv+1"
	   done
fi
