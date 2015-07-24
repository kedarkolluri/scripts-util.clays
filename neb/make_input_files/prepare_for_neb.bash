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
