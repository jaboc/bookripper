#!/bin/bash
#
#	Audiobook Ripper :	I like audio books but I dislike CD's everywhere. 
#						I like one big mp3 file to play in my audiobook player or mort player on my phone.
#						This script accepts any number of CD's and rips them with cdparanioa then concatednates 
#						then encodes the result into one variable bitrate mp3. 
#
#
#
niceness=10
tempdir=$(mktemp -d)
cachedir="/home/damonj/.bookrip_cache"
cd $tempdir

[ -d $cachedir ] && rm -rf $cachedir/*
[ -d $cachedir ] || mkdir $cachedir
[ -d $cachedir ] || $(echo "Failed to create the cache dir."; exit 8)
 

cdparanoia -qQL 2>&1 /dev/null
 

#enter Y|N
#read -n 1 -s result
#echo blash $result


echo -n "Enter the Author name, followed by [ENTER]:"
read author
echo -n "Enter the book title, followed by [ENTER]:"
read title
echo -n "Enter a comment, followed by [ENTER]:"
read comment


CD_count=1

cdparanoia -qQL  2>&1 /dev/null
maxtrack=$(cat $tempdir/cdparanoia.log  | grep -B 1 TOTAL | head -1 | cut -d ' ' -f 2 | sed 's/\.//')
echo "Max  : $maxtrack"

echo "Ripping CD"
nice -n $niceness cdparanoia -q 1-$max $cachedir/$CD_count.wav 2>&1 /dev/null
((CD_count++))
eject

if [ -z $DISPLAY ] ; then gui=false; fi

while :
do
	zenity --question --text="Is there another CD?"
	if [ $? == 0 ]; then 
		cdparanoia -qQL  2>&1 /dev/null
		maxtrack=$(cat $tempdir/cdparanoia.log  | grep -B 1 TOTAL | head -1 | cut -d ' ' -f 2 | sed 's/\.//')
		echo $maxtrack
		echo "Ripping CD"
		nice -n 15 cdparanoia -q 1-$max $cachedir/$CD_count.wav 2>&1 /dev/null
		((CD_count++))
		eject
	else
		break
	fi
done

echo "Completed ripping... moving on."
cd $cachedir 
	
echo "Encoding wavs with lame"
for i in *.wav; do nice -n $niceness lame -V 9 $i; done

echo "Wrapping mp3 with mp3wrap"
mp3wrap result.mp3 $(ls -1 *.mp3 | sort)

echo "Running the result throught lame to correct the meta data"
nice -n $niceness lame -V 9 result_mp3wrap.mp3 result.mp3

echo "Setting ID3 tags"
id3 -1 -2  -n 1 -l "$title" -t "$title" -a "$author" -g "audiobook" -c "$comment" result.mp3 


echo "Moving finished file into home"
mv result.mp3 ~/"$title.mp3"

echo "Removing cache directory"
cd
#rm -rf $cachedir
echo "Finished"
