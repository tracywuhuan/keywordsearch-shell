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
echo "keywords:";
echo "$keywords" | while read line
do
    echo "$line"
done

exclude=`awk '/\[exclude\]/,/\[end\]/{if(i>1)print x;x=$0;i++}' $1`
echo "exclude:";

for i in ${exclude[@]}  
do
    echo "$i"
done

echo "-------------------"
function scandir
{
	touch mf
	> mf
	touch umf
	> umf
	touch tempfile
	> tempfile
	echo "$keywords" >> tempfile
	findparameter=""
	for i in ${exclude[@]}  
	do
		findparameter=" -name ""$i"" -prune -o ""$findparameter"
	done
	#echo "$findparameter"
	findtype="*.$2"
	finddir=$1
	findcommand="find ""$finddir""$findparameter"" -type f -name ""\"$findtype\""
	echo "$findcommand"
	files=$(eval $findcommand)
	for file in ${files[@]}
	do
		#echo ${cur_dir}/${dirlist}
		filename=$file 
		let scannedfiles+=1 #((scannedfiles++));
        #echo "$scannedfiles""/""$filesnum"
        echo "current file is :"$filename >> $datelog
		echo "#############################################################" >>$datereport
	    echo $filename >>$datereport
		flag=""
		while read keyword
	    	do
			#get keyword line numbers				
			line=$(sed -n '/'"$keyword"'/=' "$filename" 2>/dev/null)
			#value=$(grep -E ${keyword} $filename -n)
			#echo ${value}
			if [ -n "$line" ]
			then
				flag="match"
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
		if [ "$flag" != "" ] #matched
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

