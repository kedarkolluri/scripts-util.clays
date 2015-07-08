for i in {1..5}
do
lbnl_processor_exec.out convert_VESTA filename 10by10by4_structure-Si2Al.xyz make_illite keep_ghosts CUTOFF_FILE cutoff_file.illite SAVE_LAMMPS CHARGE MOLECULE > $i.out 2>&1
mkdir -p anneal/$i

cp dat_lammps.20 anneal/$i/dat_lammps.0
cp in.anneal_ghosts anneal/$i/

cd anneal/$i/
lmp_git_openmpi_021415 -in in.anneal_ghosts -screen none
cd ../../

done

mkdir collate
mkdir collate-base
for file in {1..20}
do
  cd $file/

  filename=$(ls -lt dat_lammps.* | awk '{if (NR==2) print $(NF)}')
  file2name=$(ls -lt dat.* | awk '{if (NR==1) print $(NF)}')
  cp $filename ../collate/dat_lammps.$file
  cp $file2name ../collate/dat.$file.gz
  cp dat_lammps.0 ../collate-base/dat_lammps.$file
  cp dat.0.gz ../collate-base/dat.$file.gz
  cd ../

done



echo $prevEnergy $currEnergy | awk 'BEGIN {ret=0; prob=0;}{prob=exp(-1.0*11609.9751*($2-$1)/'$tmp');print prob; if(prob >= 1.0) {ret=1} else {val=srand('$(date +%s)'); aran = rand(); print aran; if(aran <= prob) ret=1}} END{print ret}'



enfile="energies.data"; if [ -e $enfile ]; then rm $enfile; fi; touch $enfile; for file in {0..1000}; do if [ -e dat.$file.gz ]; then gunzip -c dat.$file.gz | awk 'BEGIN{sum=0}{if($1*3>0) sum=sum+$15} END{printf("%d %lf\n", '$file',sum)}' >> $enfile; fi; done;


plotfile="plot.plot"
if [ -e $plotfile ]
then
rm $plotfile
fi


echo "set terminal postscript color solid enhanced 'Helvetica' 24
set output 'rdfplots.ps'" >> $plotfile

val=3
while [ $val -le 23 ]
do

echo "rdf1=$val
rdf2=rdf1+1

set title 'rdf $val'
set yrange[:10]
set xrange[*:8]
plot 'krdf.data.0' using 2:rdf1 w lp lt -1 pt 7 title '0', 'krdf.data.min' using 2:rdf1 w lp lt 1 pt 7 title '25'

#pause 4
set yrange[*:*]
set xrange[*:8]
set title 'cumulate $val'
plot 'krdf.data.0' using 2:rdf2 w lp lt -1 pt 7 title '0', 'krdf.data.min' using 2:rdf2 w lp lt 1 pt 7 title 'minimized'
" >> $plotfile

val=$(($val+2))

done


## RDF PLOTS
for file in {1..20}; do cp krdf.data.0.$file krdf.data.0; cp krdf.data.min.$file krdf.data.min; gnuplot plot.plot ; mv rdfplots.ps rdfplots.$file.ps; ps2pdf14 rdfplots.$file.ps; rm rdfplots.$file.ps; done;



cd collate-base

for file in {1..20}
do
cp dat_lammps.$file dat_lammps.try
lmp_git_openmpi_021415 -in in.minimize.rdfs -screen none
mv krdf.data ../rdfs/krdf.data.0.$file
done

cd ../


cd collate

for file in {1..20}
do
cp dat_lammps.$file dat_lammps.try
lmp_git_openmpi_021415 -in in.minimize.rdfs -screen none
mv krdf.data ../rdfs/krdf.data.min.$file
done

cd ../


awk '{if($1=="processing") {p = $4}; if($1=="atom") print p " " $3 " " $11 " " $10 " " $11 " " $12 " " $13 " " $14 " " $7 " " $15}' out.out


### preparing data for NEB -- BEGIN
### PLEASE READ in FULL BEFORE RUNNING THIS-
### It has all steps some of which you may not want to use every time!
###/Users/KedarKolluri/Documents/projects/LBNL/expts/base_structure/for_dft/collate/without_ghosts/for_neb
for file in {4..8}
do
  if [ -d $file ]
  then
  cd $file/;
  pwd
  ### step 1:
  ## the file dat.0.gz is the starting point (from annealing)
  ## if MD was not done or dat_lammps.0.gz exists, skip this step and go to second step where the size is replicated if needed

  #cp dat_lammps.postMD.gz dat_lammps.00.gz
  #gunzip dat_lammps.00.gz
  #lmp_openmpi_1214 -in /Users/KedarKolluri/Documents/projects/LBNL/expts/scripts/neb/make_input_files/in.illite.minimize -screen none -log log.minimize_replicated
  ##-in /Users/KedarKolluri/Documents/projects/LBNL/expts/scripts/neb/make_input_files/in.illite.minimize -screen none
  #mv dat.40000.gz dat.0.gz; rm dat_lammps.00;

  lbnl_processor_exec.out start 0 end 2 interval 22 CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.coords-first-k1gh1cs SAVE_LAMMPS CHARGE MOLECULE > out.out 2>/dev/null

  ## change the file to something else so it is saved

  awk 'BEGIN{tag=0} {if($1=="NeighborAnalyses"){if(tag==0) {tag=1;} else {tag=0;} } if(tag==1) print $0}' out.out | awk '{if(NR>1) print $0}' > input.data
  mv dat.0.gz dat.postMD.gz
#  cp dat_lammps.0.gz dat_lammps.postMD.gz

  ### step 2:
  ## run this step if we need to replicate the cell for whatever reasons (so that we can do NEB on bigger system where migration does not see it's image)
  ## this should use dat_lammps.postMD.gz as input
  ## please check before running
#  lmp_git_openmpi_021415 -in /Users/KedarKolluri/Documents/projects/LBNL/expts/scripts/neb/make_input_files/in.start_replicate_nobonds -screen none -log log.replicate

## Because replicate will need bonds to not exist, it is not minimized
## So, we need to create those bonds using lbnl_processor and then
## rerun lammps and minimize the structure

#  lbnl_processor_exec.out start 0 end 2 interval 22 CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.coords-first SAVE_LAMMPS CHARGE MOLECULE > out.create_bonds 2>&1

#  gunzip dat_lammps.0.gz; mv dat_lammps.0 dat_lammps.00

#  lmp_openmpi_1214 -in /Users/KedarKolluri/Documents/projects/LBNL/expts/scripts/neb/make_input_files/in.illite.minimize -screen none -log log.minimize_replicated

#  mv dat.40000.gz dat.0.gz; rm dat_lammps.00;

  ### step 3:
  # #the file is now saved as dat.0.gz and converted to dat_lammps.0.gz which is then converted to dat_lammps.begin
  lbnl_processor_exec.out start 0 end 2 interval 22 CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.coords-first-k1gh1cs SAVE_LAMMPS CHARGE MOLECULE > out.out 2>&1

  gunzip dat_lammps.0.gz
  mv dat_lammps.0 dat_lammps.begin

  ### step 4: (run just this if you already have dat_lammps.begin) run script to make folders that are ready to run neb
  /Users/KedarKolluri/Documents/projects/LBNL/expts/scripts/neb/make_input_files/make_inputfiles_script.bash input.data

  cd ../
fi
done

### preparing data for NEB -- END


# submitting jobs NEB
# now in 12
for filea in {1..10}; do cd $filea; for file in *; do if [ -d $file ]; then cd $file/; echo $filea $file; cp ../../run.script_hopper_regular ./; cp ../../in.neb_script ./; qsub run.script_hopper_regular; cd ../; sleep 1; fi; done; cd ../; done; qstat -u 'kkolluri' | wc


#now in 24
for filea in {11..20}; do cd $filea; for file in *; do if [ -d $file ]; then cd $file/; echo $filea $file; cp ../../run.script_edison_regular ./; cp ../../in.neb_script ./; qsub run.script_edison_regular; cd ../; sleep 1; fi; done; cd ../; done; qstat -u 'kkolluri' | wc


### collate just the log file for a set of 20 replicas
for file in {1..20}
do
  mkdir -p just_enough/$file/
  cp $file/input.data just_enough/$file/
  cd $file
    echo $file
    for file2 in *
    do
      if [ -d $file2 ]
      then
        mkdir -p ../just_enough/$file/$file2
        cp $file2/log.lammps ../just_enough/$file/$file2/
      fi
    done
  cd ../
done

## BEGIN some other processing of files (moving them around so as to not copy everything)
### not using currently

awk '{
    if( $1==500 )
    {
        for(i = 10; i <=NF; i=i+2)
  {
      print $i " " $(i+1)
  }
    }
}' log.lammps.all > neb.500.all



for file in {1..5}; do mkdir -p minimize/$file/; cp $file/initial/dat.100.gz minimize/$file/dat.0.gz; done;

for file in {1..5};
do
cp ~/Documents/projects/LBNL/expts/scripts/ion_optimization/regular_minimize/* $file/
cd $file
lbnl_processor_exec.out start 0 end 1 interval 10 SAVE_LAMMPS CHARGE MOLECULE CUTOFF_FILE cutoff_file.illite > out.out 2>&1 ; gunzip dat_lammps*;
./run_optimal.bash 0
done


awk 'BEGIN{pNR = 0; eRed=0.0} {if($3 < 0) {eRed = eRed+ $3; printf("%d %lf\n",NR-pNR, eRed); pNR = NR}}' 1/tried.pairs

for file in *;
do
if [ -d $file ]
then
cd $file
for file2 in *;
do
if [ -d $file2 ]
then
cd $file2/;
cp ../in.neb_script ./
echo $file2
mpirun -n 48 lmp_git_openmpi_021415 -partition 48x1 -in in.neb_script -screen none
cd ../../;
fi;
done;
fi
done;



for fileA in {11..20}
do
  echo "copying the folder" $fileA
  cp -R ../full/$fileA ./
  echo "done"
  echo sleep 3
  cd $fileA
  for file in *
  do
    if [ -d $file ]
    then
      echo $file/
      cd $file/
      rm log.lammps.*
      cd data
      mkdir keep
      mv dat.0.*.gz keep/
      mv dat.2000.*.gz keep/
      rm *
      mv keep/* ./
      rm -rf keep
      cd ../../
    fi
  done
  cd ../
done

## BEGIN some other processing of files (moving them around so as to not copy everything)
### not using currently


### postprocess NEB data
### extract MEPs at regular intervals
for fileA in {1..20}
do
  cd $fileA
  echo $fileA
  if [ -e barriers.collate ]
  then
    rm barriers.collate
  fi
  for file in *
  do
    if [ -d $file ]
    then
      #echo $file
      awk '{if($1==4400) print '$file' " " $7 " " $8 " " $3}' $file/log.lammps >> barriers.collate.test;
      cd $file

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
      cd ../
    fi
  done # for
  cat barriers.collate.test | sort -n > barrier.collate; rm barriers.collate.test

cd ../
done
## collate initial, final, and barrier from final MEPS
enfile="en.file.all"
for file in *
do
  if [ -d $file ]
  then
    echo $file
    cd $file/
    if [ -e $enfile ]
      then
        rm $enfile
      fi
    for file2 in *
    do
      filename="energy.neb.4400"
      if [ -e $file2/$filename ]
      then
      awk '{ if (NR==1) {INIT=$2}; printf("%lf %lf %lf\n", $1, $2, $2-INIT)}' $file2/$filename > neb.en.$file2
      awk '{if(NR==1){INIT=$2; MAX=$3}; if(MAX<$3) { MAX=$3}} END {printf("'$file2' %lf %lf %lf %lf\n", INIT, $2, MAX, (INIT+MAX-$2)) }' neb.en.$file2 >> test
      fi
    done
    cat test | sort -n >> $enfile; rm test;
    cd ../
  fi
done

### make plot.plot files
for file in *
do
  if [ -d $file ]
  then
    plotfile=plot.plot.$file

    echo "" > $plotfile

    #echo "set terminal postscript color solid enhanced 'Helvetica' 24" >> $plotfile
    #echo "set output 'nebplots.$file.ps'" >> $plotfile

    for file2 in {1..200}
    do
      if [ -e $file/neb.en.$file2 ]
      then
        echo "set title '$file and $file2'" >> $plotfile
        echo "plot '$file/neb.en.$file2' using 1:3 w lp lt -1 ps 2 pt 7 title '$file2'" >> $plotfile
        echo "pause 7" >> $plotfile
      fi
    done
  fi
done

# extract initial, final, and barriers
awk '{if(NR==1){INIT=$2; MAX=$3}; if(MAX<$3) { MAX=$3}} END {printf("%lf %lf %lf %lf\n", INIT, $2, MAX, (INIT+MAX-$2)) }'


for file in {1..20}
do
  echo "---" $file "---"
  for file2 in $file/*
  do
    if [ -d $file2 ]
      then
      echo $file
    fi
  done
done

rm energies.all
for file in {1..20}
do
  cat $file/barriers.collate.final | sort -n >> energies.all
done


awk
{
  if($7=="good")
    { HI=$5; LOW=$6; if(HI<LOW) {T=HI; HI=LOW;LOW=T;}; printf("%lf %lf %d %d \n", HI, LOW,$1,$2)
    }
}

for file in {1..20}
do
  cp dat.$file.gz dat.0.gz
  lbnl_processor_remove_ghosts_exec.out start 0 end 1 interval 22 CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.coords-first SAVE_LAMMPS CHARGE MOLECULE > out.$file 2>&1
  mv dat_lammps.0.gz dat_lammps.$file.gz
done






## collect data of atoms moved for analyses (statistical)
#ID, total coord, Sia, Ala, K, Ob, Gh
for file in {1..20}
do
  if [ -d $file ]
    then
    cd $file

    for file2 in  *
    do
      if [ -d $file2 ]
      then
        cd $file2
        echo $file $file2

        mkdir postp
        cp data/dat.2000.1.gz postp/dat.0.gz
        cp data/dat.2000.48.gz postp/dat.1.gz

        cd postp

        lbnl_processor_latest_exec.out start 0 end 1 interval 10 CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.coords-first SAVE_LAMMPS CHARGE MOLECULE > out.1 2>/dev/null
        lbnl_processor_latest_exec.out start 1 end 2 interval 10 CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.coords-first SAVE_LAMMPS CHARGE MOLECULE > out.2 2>/dev/null

        awk '{if(($1=="atom")&&($2=="id")) printf("%d %d %d %d %d %d %lf\n", $3+1, $7, $9, $10, $11, $12, $14)}' out.1 > a.1
        awk '{if(($1=="atom")&&($2=="id")) printf("%d %d %d %d %d %d %lf\n", $3+1, $7, $9, $10, $11, $12, $14)}' out.2 > a.2

        awk '{if(($1=="total") && ($2=="energy")) printf("%lf\n", $4) }' out.1 > en.1
        awk '{if(($1=="total") && ($2=="energy")) printf("%lf\n", $4) }' out.2 > en.2

        paste a.1 a.2 > coords.out1
        awk '{if(($7-$14)^2 > 0.001) printf("%s %d %d %d %d %d %lf\n", $0, -$2+$9, -$3+$10, -$4+$11, -$5+$12, -$6+$13, -$7+$14)}' coords.out1 > coords.out
        awk '{printf("%s %d %d %d %d %d %lf\n", $0, -$2+$9, -$3+$10, -$4+$11, -$5+$12, -$6+$13, -$7+$14)}' coords.out1 > coords.out.all
        awk 'BEGIN{totk=0; sia=0; ala=0; k=0; ob=0} {totk=totk+$9-$2; sia=sia+$10-$3; ala=ala+$11-$4; k=k+$12-$5; ob=ob+$13-$6}END{printf("%d %d %d %d %d\n", totk, sia, ala, k, ob)}' coords.out1 > coords.sum
        paste coords.sum en.1 en.2 > coords_ener.sum
        rm out.1 out.2 a.1 a.2 en.1 en.2 coords.out1

        cd ../

        cd ../
      fi
    done

    cd ../
  fi
done


for i in {1..20}
do
  mkdir $i
  lbnl_processor_latest.out convert_VESTA filename DFT_smallest_structure-Si2Al.xyz make_illite keep_ghosts CUTOFF_FILE  /Users/KedarKolluri/lib/cutoff_file.illite.make SAVE_LAMMPS CHARGE MOLECULE > $i.out 2>&1
  cp dat_lammps.20 $i/dat_lammps.0
  sleep 3
done



lbnl_processor_latest_exec.out convert_VESTA filename 6by4by2_structure-Si2Al.xyz make_illite keep_ghosts CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.make-cs rand_seed 1 SAVE_LAMMPS CHARGE MOLECULE > out.$iter 2>&1
