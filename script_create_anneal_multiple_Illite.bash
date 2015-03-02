for i in {1..20}
do
lbnl_processor_exec.out convert_VESTA filename small_3x_structure-Si2Al.xyz make_illite keep_ghosts CUTOFF_FILE cutoff_file.illite SAVE_LAMMPS CHARGE MOLECULE > $i.out 2>&1
mkdir -p anneal/$i

cp dat_lammps.20 anneal/$i/dat_lammps.0
cp in.anneal_ghosts anneal/$i/

cd anneal/$i/
lmp_git_openmpi_021415 -in in.anneal_ghosts -screen none
cd ../../

done





echo $prevEnergy $currEnergy | awk 'BEGIN {ret=0; prob=0;}{prob=exp(-1.0*11609.9751*($2-$1)/'$tmp');print prob; if(prob >= 1.0) {ret=1} else {val=srand('$(date +%s)'); aran = rand(); print aran; if(aran <= prob) ret=1}} END{print ret}'




42055 42055 25 K 1 0.479176 0.909645 0.423519 -57.1343 -14.2076 35.7873 0 0 0 -13.0304
42410 42410 26 Gh 0 0.596355 0.441619 0.177911 -44.2799 -35.0669 15.0335 0 0 0 0 
