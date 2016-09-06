#!/bin/sh

datename=$(date +%Y%m%d)            #getdate
datelog=`pwd`"/"$datename".log"
datereport=`pwd`"/"$datename".report"

if [ ! -e "$datelog" ]; then
     echo $datelog" create!" 
     touch $datelog             #createlogfile
else
     echo "file exists,will overwrite!"
     cat /dev/null > $datelog
fi 

if [ ! -e "$datereport" ]; then
     echo $datereport" create!" 
     touch $datereport             #createreportfile
else
     echo "file exists,will overwrite!"
     cat /dev/null > $datereport
fi 
####config.ini
filelist=`awk '/\[fileType\]/,/\[keyWord\]/{if(i>1)print x;x=$0;i++}' $1`
####print
echo "supported filetype:";
for i in ${filelist[@]}  
do  
    echo "$i"
done 
####config.ini
keywords=`awk '/\[keyWord\]/,/\[exclude\]/{if(i>1)print x;x=$0;i++}' $1`
####print
echo "$keywords" | while read line
do
    echo "$line"
done

exclude=`awk '/\[exclude\]/,/\[end\]/{if(i>1)print x;x=$0;i++}' $1`
echo "$exclude" | while read line
do
    echo "$line"
done

echo "-------------------"
function scandir
{
	matchedfiles=0
	touch mf
	touch umf
	echo "$keywords" >> tempfile
	for file in $(find $1 -type f -name "*.$2") # not $(ls ${cur_dir})  maybe filename contains space
	do
		continueflag=0
		 #echo ${cur_dir}/${dirlist}  
            	filename="$file"
		echo "$exclude" >> tempfile2
		while read excludedir
		do
			if [[ $filename =~ $exclude ]]
			then
				continueflag=1
			fi
		done < tempfile2
		rm tempfile2
		if [ "$continueflag" == "1" ]
		then
			continue
		fi
            	echo "current file is :"$filename >> $datelog
	    	echo "#############################################################" >>$datereport
	    	echo $filename >>$datereport
		let scannedfiles+=1 #((scannedfiles++));
		flag=0
		while read keyword
	    	do
			#get keyword line numbers				
			line=$(sed -n '/'"$keyword"'/=' "$filename")
			#value=$(grep -E ${keyword} $filename -n)
			#echo ${value}
			if [ -n "$line" ]
			then
				flag=1
				echo "keyword: "$keyword >>$datereport
				for i in ${line[@]}  
				do  
					echo "line:"$i"" >>$datereport
                        		echo "$(awk 'NR=='"$i"'' "$filename")" >>$datereport #must "xx",if awk output include "*" it will echo current path's files
				done
				#echo $value >>$datelog
				else
				echo $filename":not matched" >>$datelog
			fi
		done < tempfile
		if [ "$flag" == "1" ] #matched
		then
			let matchedfiles+=1 #((matchedfiles++))i;
			echo "#############################################################" >>$datereport
			echo "" >>$datereport
			echo $filename >> mf
		else
			sed '$d' $datereport >tmp1
			sed '$d' tmp1 > tmp2
			rm tmp1
			mv tmp2 $datereport
			echo $filename >> umf
		fi
	done
	notmatchedfiles=$[$scannedfiles-$matchedfiles]
	echo "Summary=============================================================================================" >>$datereport
	echo $scannedfiles" files checked, "$matchedfiles" files matched, "$notmatchedfiles" files not matched" >>$datereport
	echo "#################################" >>$datereport
	echo "The list of matched files:" >>$datereport
	cat mf >> $datereport
	echo "#################################" >>$datereport
	echo "The list of unmatched files:" >>$datereport
	cat umf >> $datereport
	echo "#################################" >>$datereport
	rm tempfile
	rm mf
	rm umf
}  

#

#test -d dir
if test -d $2
then
	echo "start!!!"
	for i in ${filelist[@]}
	do
		if [[ "-" == "$i" ]]
            	then
                	scandir $2 "*"
            	else
                	scandir $2 $i
            	fi
	done
	echo "end!!!"
else
    	echo "not dir!"  
    	exit 1  
fi  

