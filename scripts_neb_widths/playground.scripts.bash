for mainfile in r*; do filename="disp.info".$mainfile; if [ -e $filename ]; then rm $filename; fi; for file in {100000..10000000}; do if [ -e ${mainfile}/data/dat.$file.gz ]; then gunzip -c ${mainfile}/data/dat.$file.gz | awk '{if (($4=="K")&&($16>2.4)) print $16 " " $1 " " '$file'}' | sort -nr >> $filename; fi; done; done;

# print energies for each of the states
# run postprocess and create lammps files for NEB
# this assume initial file in 100 and there are upto only 120 files
# this also assumes the folder structure is folder/minimized_data/
for filemain in *
do
if [ -d $filemain/minimized_data ]
then
cd $filemain/minimized_data
echo "**"$filemain"**"
flag=0
base=0.0
lbnl_processor_exec.out start 100 end 120 interval 1 CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.coords-first-k1gh1cs SAVE_LAMMPS CHARGE MOLECULE > out.out 2>&1
for file in {100..120}
do
if [ -e dat_lammps.$file.gz ]
then
gunzip -c dat_lammps.$file.gz | awk '{if(NR==3) {print $1}; if(NF==7) printf("%d %lf  %lf  %lf\n", $1, $5, $6, $7)}' > end.coords.$file
fi
if [ -e log.lammps.$file ]
then
if [ $flag -eq 0 ]
then
base=$(awk '{if ($1==40000) print $5}' log.lammps.$file)
flag=1
#echo $base "is the base"
fi
awk '{if ($1==40000) {res='$base'; printf("%lf\n", $5-res)}}' log.lammps.$file
fi
done
cd ../../
fi
done



# run NEB on hopper
for filemain in *
do
if [ -d $filemain/minimized_data ]
then
cp neb.script.here $filemain/minimized_data/
cp run.script_hopper_regular $filemain/minimized_data/
cd $filemain/minimized_data
echo "**"$filemain"**"
qsub run.script_hopper_regular
sleep 1
cd ../../
fi
done

## extract MEPs at regular intervals

if [ -e barriers.collate ]
then
  rm barriers.collate
fi
for file in *
do
  if [ -e $file/minimized_data/log.lammps ]
  then
    echo $file
    awk '{if($1==4400) print '$file' " " $7 " " $8 " " $3}' $file/minimized_data/log.lammps >> barriers.collate;
    cd $file/minimized_data

    j=0; while [ $j -le 4400 ]
    do
    awk '{
        if( $1=='$j' )
        {
            for(i = 10; i <=NF; i=i+2)
    	{
    	    print $i " " $(i+1)
    	}
        }
    }' log.lammps > energy.neb.$j

    if [ $(wc energy.neb.$j | awk '{print $1}') -lt 1 ]; then rm energy.neb.$j ; fi

    j=$(($j+1100))
    done # while
    cd ../../
  fi
done # for

## collate NEBs
enfile="en.file.all"
for file in *
do
  if [ -d $file/minimized_data ]
  then
    echo $file
    cd $file/minimized_data
    if [ -e $enfile ]
      then
        rm $enfile
    fi
    filename="energy.neb.4400"
    if [ -e $filename ]
    then
      awk '{ if (NR==1) {INIT=$2}; printf("%lf %lf %lf\n", $1, $2, $2-INIT)}' $filename > neb.en
      awk '{if(NR==1){INIT=$2; MAX=$3}; if(MAX<$3) { MAX=$3}} END {printf("'$file' %lf %lf %lf %lf\n", INIT, $2, MAX, (INIT+MAX-$2)) }' neb.en >> test
    fi
    cat test | sort -n >> $enfile; rm test;
    cd ../../
  fi
done
