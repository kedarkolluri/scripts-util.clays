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
for file in {1..20}
do
  cd $file/;
  pwd
  ### step 1:
  # the file dat.0.gz is the starting point (from annealing)
  # if MD was not done or dat_lammps.0.gz exists, skip this step and go to second step where the size is replicated if needed
  lbnl_processor_exec.out start 0 end 2 interval 22 CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.coords-first SAVE_LAMMPS CHARGE MOLECULE > out.out 2>/dev/null
  # change the file to something else so it is saved
  awk 'BEGIN{tag=0} {if($1=="NeighborAnalyses"){if(tag==0) {tag=1;} else {tag=0;} } if(tag==1) print $0}' out.out | awk '{if(NR>1) print $0}' > input.data
  mv dat.0.gz dat.postMD.gz
  cp dat_lammps.0.gz dat_lammps.postMD.gz

  ### step 2:
  # run this step if we need to replicate the cell for whatever reasons (so that we can do NEB on bigger system where migration does not see it's image)
  #lmp_git_openmpi_021415 -in /Users/KedarKolluri/Documents/projects/LBNL/expts/scripts/neb/make_input_files/in.start_replicate

  ### step 3:
  # the file is now saved as dat.0.gz and converted to dat_lammps.0.gz which is then converted to dat_lammps.begin
  #lbnl_processor_exec.out start 0 end 2 interval 22 CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.coords-first SAVE_LAMMPS CHARGE MOLECULE > out.out 2>&1

  gunzip dat_lammps.0.gz
  mv dat_lammps.0 dat_lammps.begin

  ### step 4: (run just this if you already have dat_lammps.begin) run script to make folders that are ready to run neb
  /Users/KedarKolluri/Documents/projects/LBNL/expts/scripts/neb/make_input_files/make_inputfiles_script.bash input.data

  cd ../
done

### preparing data for NEB -- END

### postprocess NEB data
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
      awk '{if($1==2020) print '$file' " " $7 " " $8 " " $3}' $file/log.lammps >> barriers.collate;

      cd $file

      j=0; while [ $j -le 2020 ]
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

      j=$(($j+100))
      done # while
      cd ../
    fi

  done # for
cd ../
done



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
  echo "coping the folder" $fileA
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
