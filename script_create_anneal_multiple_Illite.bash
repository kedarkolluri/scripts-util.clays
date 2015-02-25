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
