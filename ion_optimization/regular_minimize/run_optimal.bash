#!/bin/bash

# lammps input files are of the format LMPINPUT.NUM
# where LMPINPUT is any string of your choice but we recommend that you start with 0
# for example `dat_lammps.0` is an acceptable file but `dat_lammps` is not
#1 starting number of the lammps input file

current=$1

## You can change below parameters to suit your input, lammps, and output constraints
lammpsPrefix="dat_lammps"
kionID=7
gionID=11
lmpexec="mpirun -np 2 lmp_git_openmpi_021415"
lmpinput="in.swap_ghosts_minimize"
lmpoutput="log.lammps"
lmpdataout1="dat.50000" # the actual is needs to be zipped (dat.50000.gz)
lmpmetadata1="metadata1.dat"
lmpmetadata2="metadata2.dat"

### None of the code below is parameterize friendly
### If anything breaks after you change stuff below and you are having difficulty fixing it,
### please write to me at kkolluri@lbl.gov for

lmpdataout=$lmpdataout1.gz

thisCommand=$0
minimize=1 # 0 is false, 1 is true
tmp=500
nloops=1
totalsize=$#
while [ $# -gt 0 ]
do
    if [ $totalsize -eq $# ]
    then
	shift
    fi

    case $1 in
	-minimize)
	    minimize=1
	    shift
	    ;;
	-MC)
            minimize=0
	    shift
	    echo $tmp
	    if [ $(echo $tmp | awk 'BEGIN {ret = 0} {if ($1*1> 0) ret=1;} END{print ret}') -ne 1 ]
	    then
		echo "the parameter after MC should be a temp (in Kelvin), which is a number"
		echo "example: -MC 1200"
		exit 1
	    else
		tmp=$1
		echo "temperature is" $tmp
	    fi
	    shift
            ;;
	-loops)
	    shift
	    nloops=$1
	    if [ $(echo $nloops | awk 'BEGIN {ret = 0} {if ($1*1> 0) ret=1;} END{print ret}') -ne 1 ]
	    then
		echo "the parameter after loops should be an integer number (tip: use if you want more than 1)"
		echo "example: -loop 2"
		exit 1
	    else
		echo "number of times to loop is" $nloops
	    fi
	    shift
	    ;;
	*)
	    echo ""
	    echo "Unknown argument $1....ignoring "
	    echo ""
	    shift
	    ;;
    esac
done


echo " "
echo "USAGE example :" $thisCommand "0"
echo "***"
echo "This code swaps cations with ghost positions to minimize energy"
echo " "
echo "lammps input files are of the format LMPINPUT.NUM"
echo "where LMPINPUT is any string of your choice"
echo "NUM is a number corresponding to number of swaps made; we recommend that you start with 0"
echo "for example dat_lammps.0 is an acceptable file but dat_lammps is not"
echo " "
echo "Parameters for this run are the following---"
echo "Starting data file for this run is:" $current
echo "Prefix of lammps files:" $lammpsPrefix
echo "ID of ion used in the data file (not infered from data file!):" $kionID
echo "ID of ghost used in the data file (not infered from data file!):" $gionID
echo "name of the lammps executable:" $lmpexec
echo "name of the lammps inputfule:" $lmpinput
echo "name of the lammps output file:" $lmpoutput
echo "This input file outputs" $lmpdataout "which is read again by this script"
echo "storing the metadeta of the lammps input file in" $lmpmetadata1 "and" $lmpmetadata2
echo " "
echo "NOTE: If any these are different, please change them in this script before running it"
echo "***"

if ! [[ $current =~ ^[0-9]+$ ]] ;
then
    #exec >&2;
    echo "datafile suffix (1st parameter) is not a number"
    echo ""
    exit 1
else
    if ! [[ -e $lammpsPrefix.$current ]]
    then
	echo "file" $lammpsPrefix.$current "does not exist"
	echo ""
	exit 1
    fi
fi

if ! type $lmpexec > /dev/null 2>&1;
then
    echo "lammps executable" $lmpexec "does not exist in the path"
    echo ""
    exit 1
fi

tr -d $'\r' < $lammpsPrefix.$current | awk 'BEGIN {read="true"} {if( ($1!="Atoms")&&(read=="true") ) { print $0} else { read = "false"} }' > $lmpmetadata1
echo "Atoms" >> $lmpmetadata1
echo " " >> $lmpmetadata1

tr -d $'\r' < $lammpsPrefix.$current | awk 'BEGIN {read="false"}
{
if( ($1=="Bonds") || ($1=="Angles") ) { read="true" }
if(read=="true")
{
print $0
}
}' > $lmpmetadata2


if [ $current -eq 0 ]
then
    if [ -e tried.pairs ]
    then
	    cp tried.pairs tried.pairs.bkp
	    rm tried.pairs
	    echo "copied tried.pairs to a backup file tried.pairs.bkp and deleted the file"
    fi
    echo "creating a new tried.pairs file to store combinations that were tried"
    touch tried.pairs
fi
touch tried.pairs

cp $lammpsPrefix.$current  $lammpsPrefix.try

$lmpexec -in $lmpinput -screen none

mv $lmpdataout dat.$current.gz

# get the energy out
prevEnergy=$(awk '{if($1==50000) print $2}' $lmpoutput)

#echo "prev energy is " $prevEnergy

tmpExit=1
#iter=0
iter=$(wc tried.pairs | awk '{print $1}')
while [ $tmpExit -eq 1 ]
do

    if [ $minimize -eq 1 ]
    then
	tmpExit=0
    fi

    echo "finding a distribution better than that in" $lammpsPrefix.$current
    #store the ids of ions in a string to be accessed by awk


    kions=$(gunzip -c dat.$current.gz | awk '{if($3=='$kionID') printf("%lf %d\n", $15,$1)}' | sort -nr | awk '{print $2}')
    nkions=$(echo $kions | awk '{print NF}')

    xkions=$(gunzip -c dat.$current.gz | awk '{if($3=='$kionID') printf("%lf %d %lf\n", $15,$1, $9)}' | sort -nr | awk '{print $3}')
    ykions=$(gunzip -c dat.$current.gz | awk '{if($3=='$kionID') printf("%lf %d %lf\n", $15,$1, $10)}' | sort -nr | awk '{print $3}')
    zkions=$(gunzip -c dat.$current.gz | awk '{if($3=='$kionID') printf("%lf %d %lf\n", $15,$1,$11)}' | sort -nr | awk '{print $3}')


#    kions=$(awk '{if($3=='$kionID') print $1}' $lammpsPrefix.$current)
#    nkions=$(echo $kions | awk '{print NF}')
#
#    xkions=$(awk '{if($3=='$kionID') print $5}' $lammpsPrefix.$current)
#    ykions=$(awk '{if($3=='$kionID') print $6}' $lammpsPrefix.$current)
#    zkions=$(awk '{if($3=='$kionID') print $7}' $lammpsPrefix.$current)
#

    #echo "ions are " $nkions

    gions=$(awk '{if($3=='$gionID') print $1}' $lammpsPrefix.$current)
    ngions=$(echo $gions | awk '{print NF}')

    xgions=$(awk '{if($3=='$gionID') print $5}' $lammpsPrefix.$current)
    ygions=$(awk '{if($3=='$gionID') print $6}' $lammpsPrefix.$current)
    zgions=$(awk '{if($3=='$gionID') print $7}' $lammpsPrefix.$current)

    #echo "ghosts are " $ngions

    iterKion=1


    while [ $iterKion -le $nkions ]
    do
#	if [ $minimize -eq 0 ]
#	then
#	    iterKion=$(echo $iterKion | awk '{if(NR==1) print '$RANDOM'%'$nkions'+1}')
#	fi
	skion=$(echo $kions | awk '{print $('$iterKion')}')
	sxkion=$(echo $xkions | awk '{print $('$iterKion')}')
	sykion=$(echo $ykions | awk '{print $('$iterKion')}')
	szkion=$(echo $zkions | awk '{print $('$iterKion')}')

	iterGion=1
	while [ $iterGion -le $ngions ]
	do
#	    if [ $minimize -eq 0 ]
#	    then
#		iterGion=$(echo $iterGion | awk '{if(NR==1) print '$RANDOM'%'$ngions'+1}')
#	    fi
	    sgion=$(echo $gions | awk '{print $('$iterGion')}')
	    sxgion=$(echo $xgions | awk '{print $('$iterGion')}')
	    sygion=$(echo $ygions | awk '{print $('$iterGion')}')
	    szgion=$(echo $zgions | awk '{print $('$iterGion')}')

	    #echo "trying swap " $skion $sgion $iterKion $iterGion

	    havetried=$(awk 'BEGIN{ret=0; sum=0}{if( ($1=='$skion') && ($2=='$sgion')) sum=sum+1} END {if (sum >= '$nloops') {ret=1}; print ret}' tried.pairs)

	    if [ $minimize -eq 0 ]; then havetried=0; fi

	    if [ $havetried -eq 0 ]
	    then
#		echo "trying swap " $skion $sgion $iterKion $iterGion
		#echo "not tried.. going ahead with an attempt"


		#rm dat_lammps.try
		awk '{
	        if( ($1=='$skion') && ($3=='$kionID') )
		{
                   printf("%d %d %d %lf %lf %lf %lf\n", $1, $2, $3, $4, '$sxgion', '$sygion', '$szgion')

		}else if( ($1=='$sgion') && ($3=='$gionID') )
		{
                   printf("%d %d %d %lf %lf %lf %lf\n", $1, $2, $3, $4, '$sxkion', '$sykion', '$szkion')

		}else
		{
		    print $0
		}

	    }' $lammpsPrefix.$current > $lammpsPrefix.try

		#echo "create the lammps file here... running lammps on it now"
		iter=$(($iter+1))
		$lmpexec -in $lmpinput -screen none

		energyExists=$(awk 'BEGIN{ret=0}{if($1==50000) ret=1} END{print ret}' $lmpoutput)
		currEnergy=$(awk 'BEGIN{ret=0}{if($1==50000) ret=$2} END{print ret}' $lmpoutput)

		if [ $energyExists -eq 0 ]
		then
		    cp $lammpsPrefix.try $lammpsPrefix.fail.$skion.and.$sgion
		    cp $lammpsPrefix.$current $lammpsPrefix.fail_prev.$skion.and.$sgion
		    cp $lmpoutput $lmpoutput.fail.$skion.and.$sgion
		    echo "error with this swap " $skion $sgion $iterKion $iterGion
		    echo "there is an error, see the saved lammps and log files"
		    exit
		fi


		#	    echo "prev and new energies are " $prevEnergy $currEnergy
		# 0 is false.. anything else is true
		ediff=$(echo $prevEnergy $currEnergy | awk '{print $2-$1}')

		accept=0 #default don't accept
    if [ $minimize -eq 1 ]
		then
		    accept=$(echo $prevEnergy $currEnergy | awk 'BEGIN{ret=0}{if($1 > $2) ret=1} END {print ret}')
		else
		    retval=$(echo $prevEnergy $currEnergy | awk 'BEGIN{ret=0; prob=0;prob2=0;}{ prob= exp(-1.0*11609.9751*($2-$1)/'$tmp'); if (prob>=1) { prob =1 ; ret=1} else { srand('$(date +%s)'); prob2=rand(); if (prob2 < prob) ret=1 }; } END {print ret " " prob " " prob2}')

		    accept=$(echo $retval | awk '{print $1}')

#		    accept=$(echo $prevEnergy $currEnergy | awk 'BEGIN{ret=0}{ prob= exp(-1.0*11609.9751*($2-$1)/'$tmp'); if (prob>=1) { ret=1} else { srand('$(date +%s)'); if (rand() > prob) ret=1 }; } END {print ret}')
		fi
		testcurr=$(echo $current | awk '{print $1+'$accept'}')
    effratio=$(echo $testcurr $iter | awk '{printf("%4.2lf\n", $1/$2)}')
		echo $skion $sgion $ediff $accept $retval $testcurr $iter $effratio >> tried.pairs
		if [ $accept -eq 1 ]
		then
		    current=$(($current+1))
		    if [ -e $lmpdataout ]
		    then

			echo "accepted: energy info " $skion $sgion $iterKion $iterGion $ediff

      cp $lmpdataout dat.$current.gz

			cat $lmpmetadata1 > $lammpsPrefix.$current
			gunzip -c $lmpdataout | awk 'BEGIN {read="false"} { if(read=="true") {printf("%d %d %d %lf %lf %lf %lf\n", $1, $2, $3, $5, $9, $10, $11)}; if($2=="ATOMS") { read="true" } }' >> $lammpsPrefix.$current
			cat $lmpmetadata2 >> $lammpsPrefix.$current
			cp $lammpsPrefix.$current $lammpsPrefix.try

### These 4 files use my own C++ code to process lammps output file
### this code has been superceeded by the 4 lines above as it is just file manipulation that I use anyways

#			lbnl_processor_exec.out start 50000 end 50001 interval 10 CUTOFF_FILE cutoff_file.illite SAVE_LAMMPS CHARGE MOLECULE > postprocess.out 2>&1
#			gunzip dat_lammps.50000.gz
#			cp dat_lammps.50000 $lammpsPrefix.$current
#			mv dat_lammps.50000 $lammpsPrefix.try


			rm $lmpoutput

			prevEnergy=$currEnergy
			iterGion=$ngions
			iterKion=$nkions
			tmpExit=1

#			echo "tmp Exit value is " $tmpExit


		    else
			echo " lammps failed, please check what happened. lammps file and log file saved"
			exit
		    fi
		else
		    #echo "not accepted..."
		    #echo " "
		    if [ -e $lmpdataout ]
		    then
			rm $lmpdataout
		    fi
		    rm $lmpoutput

		fi
#	    else
		#echo "but its already been tried...so skipping"
	    fi

	    iterGion=$(($iterGion+1))
	    #echo "next ghost to try " $iterGion
	done

	iterKion=$(($iterKion+1))
	#echo "next ion to try " $iterKion
    done

#echo "moving on to the next one now"
#echo " "
done

## commands for extracting energies for dat.*.gz files
## note that there is dat.0.gz existing!

#for file in {0..30}; do if [ -e dat.$file.gz ]; then gunzip -c dat.$file.gz | awk 'BEGIN{sum=0}{if($1*3>0) sum=sum+$15} END{printf("%d %lf\n", '$file',sum)}'; fi; done;
