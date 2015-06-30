## This file creates multiple folders each
## of which has 1 NEB path's initial and final states
## This is run as part of another bash loop
## That loops will prepare the system
## in that, it will list of atoms to move and the distances they should be moved
## As of April 2, that script is in script_create_anneal_multiple_Illite.bash
## it should be 2 folders above this one!

initfile="dat_lammps.begin"
finalfile="dat_lammps.end"
enstore="energies.data"
id=40000
if [ -e $enstore ]
then
    rm $enstore
fi

let i=1
while IFS=$'\n' read -r linedata
do
    IFS=" " read -a vals <<< "$linedata"
    a=${vals[0]}
    x=${vals[1]}
    y=${vals[2]}
    z=${vals[3]}
    tag=$i
    mkdir $tag
    echo $a > $tag/atom_id.info
    echo $tag
    cp  $initfile $tag/

    awk 'BEGIN{first = 1}
         {
           if(($1=='$a') &&(first==1)) {
           first=0;
           printf("%d %d %d %lf %12.9lf %12.9lf %12.9lf\n", $1, $2, $3, $4, $5+'$x',$6+'$y',$7+'$z')
         }else
         {
           print $0;
         }
        }' $initfile > dat_lammps.00


cp /Users/KedarKolluri/Documents/projects/LBNL/expts/scripts/neb/make_input_files/in.illite.minimize ./

#echo "running lammps now to find end structure"

lmp_openmpi_1214 -in in.illite.minimize -screen none -log log.lammps.$tag

#echo "finished lammps run"

awk '{if($1=='$id') print $0}' log.lammps.$tag | awk 'END{print '$tag' " " $5}' >> $enstore

#echo "extracted energy"

lbnl_processor_exec.out start $id end $(($id+2)) interval 22 CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.coords-first-k1gh1cs SAVE_LAMMPS CHARGE MOLECULE > out.out 2>&1

#echo "created lammps file for this"

gunzip dat_lammps.$id.gz
mv dat_lammps.$id $tag/$finalfile

mv dat.$id.gz $tag/dat.end.gz
mv log.lammps.$tag $tag/

awk '{if(NR==3) {print $1}; if(NF==7) printf("%d %lf  %lf  %lf\n", $1, $5, $6, $7)}' $tag/$finalfile > $tag/end.coords

boxinfo=$(awk '{if($NF=="pdbformat") print $1 " " $2 " " $3 " " $4 " " $5 " " $6}' out.out)

awk '{if(NF==7) printf("%lf  %lf  %lf\n", $5, $6, $7)}' $tag/$initfile > data.init
awk '{if(NF==7) printf("%lf  %lf  %lf  %d\n", $5, $6, $7, $1)}' $tag/$finalfile > data.final


paste data.init data.final > combined.data


awk -v var="$boxinfo" '{system("wrap_and_dist.out " var " "$1 " " $2 " " $3 " " $4 " " $5 " " $6)}' combined.data > diff.combined.data
paste diff.combined.data data.final | sort -nr > combined.data
awk 'BEGIN {natoms=50; print natoms;}{if(NR <= natoms) printf("%d  %lf  %lf  %lf\n",$8, $5, $6, $7)}' combined.data > $tag/end.coords.small

mv combined.data $tag/

rm data.init data.final
rm diff.combined.data

cp /Users/KedarKolluri/Documents/projects/LBNL/expts/scripts/neb/in.neb_script $tag/


((i++))

done < $1
