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
lmpexec="lmp_git_openmpi_021415"
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

if [ -z "$1" ]
  then
    echo " "
    echo "INPUT ERROR: No argument supplied.. please read above"
    echo " "
    exit
fi

awk 'BEGIN {read="true"} {if( ($1!="Atoms")&&(read=="true") ) { print $0} else { read = "false"} }' $lammpsPrefix.$current  > $lmpmetadata1
echo "Atoms" >> $lmpmetadata1
echo " " >> $lmpmetadata1

awk 'BEGIN {read="false"} 
{
if( ($1=="Bonds") || ($1=="Angles") ) { read="true" }
if(read=="true")
{
print $0
}
}' $lammpsPrefix.$current  > $lmpmetadata2


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

cp $lammpsPrefix.$current  $lammpsPrefix.try

$lmpexec -in $lmpinput -screen none

# get the energy out
prevEnergy=$(awk '{if($1==50000) print $2}' $lmpoutput)

#echo "prev energy is " $prevEnergy

tmpExit=1
while [ $tmpExit -eq 1 ]
do
    tmpExit=0
    echo "finding a distribution better than that in" $lammpsPrefix.$current
    #store the ids of ions in a string to be accessed by awk
    kions=$(awk '{if($3=='$kionID') print $1}' $lammpsPrefix.$current)
    nkions=$(echo $kions | awk '{print NF}')
    
    xkions=$(awk '{if($3=='$kionID') print $5}' $lammpsPrefix.$current)
    ykions=$(awk '{if($3=='$kionID') print $6}' $lammpsPrefix.$current)
    zkions=$(awk '{if($3=='$kionID') print $7}' $lammpsPrefix.$current)
    
    #echo "ions are " $nkions
    
    gions=$(awk '{if($3=='$gionID') print $1}' $lammpsPrefix.$current)
    ngions=$(echo $gions | awk '{print NF}')
    
    xgions=$(awk '{if($3=='$gionID') print $5}' $lammpsPrefix.$current)
    ygions=$(awk '{if($3=='$gionID') print $6}' $lammpsPrefix.$current)
    zgions=$(awk '{if($3=='$gionID') print $7}' $lammpsPrefix.$current)
    
    #echo "ghosts are " $ngions
    
    ## select one kion randomly
    #skion=$(echo $kions | awk '{print $('$RANDOM'%NF)}')
    ## select one gion randomly
    #sgion=$(echo $gions | awk '{print $('$RANDOM'%NF)}')
    
    ###
    # alternately, we can do iterations 1 through nkions and ngions but its not implemented here yet
    ###
    
    iterKion=1


    while [ $iterKion -le $nkions ]
    do
	skion=$(echo $kions | awk '{print $('$iterKion')}') 
	sxkion=$(echo $xkions | awk '{print $('$iterKion')}') 
	sykion=$(echo $ykions | awk '{print $('$iterKion')}') 
	szkion=$(echo $zkions | awk '{print $('$iterKion')}') 

	iterGion=1	
	while [ $iterGion -le $ngions ]
	do
	    sgion=$(echo $gions | awk '{print $('$iterGion')}') 
	    sxgion=$(echo $xgions | awk '{print $('$iterGion')}') 
	    sygion=$(echo $ygions | awk '{print $('$iterGion')}') 
	    szgion=$(echo $zgions | awk '{print $('$iterGion')}') 
	    
	    #echo "trying swap " $skion $sgion $iterKion $iterGion
	    
	    havetried=$(awk 'BEGIN{ret=0}{if( ($1=='$skion') && ($2=='$sgion')) ret=1} END {print ret}' tried.pairs)
	    if [ $havetried -eq 0 ]
	    then
#		echo "trying swap " $skion $sgion $iterKion $iterGion
		#echo "not tried.. going ahead with an attempt"

	    
		#rm dat_lammps.try
		awk '{
	        if( ($1=='$skion') && ($3==7) )
		{
                   printf("%d %d %d %lf %lf %lf %lf\n", $1, $2, $3, $4, '$sxgion', '$sygion', '$szgion')

		}else if( ($1=='$sgion') && ($3==11) )
		{
                   printf("%d %d %d %lf %lf %lf %lf\n", $1, $2, $3, $4, '$sxkion', '$sykion', '$szkion')

		}else
		{
		    print $0
		}
		
	    }' $lammpsPrefix.$current > $lammpsPrefix.try

		#echo "create the lammps file here... running lammps on it now"
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
		accept=$(echo $prevEnergy $currEnergy | awk 'BEGIN{ret=0}{if($1 > $2) ret=1} END {print ret}')
		ediff=$(echo $prevEnergy $currEnergy | awk '{print $2-$1}')
		echo $skion $sgion $ediff >> tried.pairs
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

#for file in {0..30}; do if [ -e dat.$file.gz ]; then gunzip -c dat.$file.gz | awk 'BEGIN{sum=0}{if($1*3>0) sum=sum+$14} END{printf("%d %lf\n", '$file',sum)}'; fi; done;
