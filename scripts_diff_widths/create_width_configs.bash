### script for creating Cs structures

## first take the structure and cut it in half
## next create illite out of it
## remember to set the sed srand(1) in c++ file before running this
## and please change back the c++ code after you run this thing!!

### these 2 commands are old -- don't use them
#awk '{if((($4>0.0) && ($4< 10.1))||(NR==2)) print $0}' 6by4by2_structure-Si2Al.xyz > 6by4by1_structure-Si2Al.xyz_data
#wc 6by4by1_structure-Si2Al.xyz_data | awk '{print $1-1}' > 6by4by1_structure-Si2Al.xyz


#### THIS awk is for when we move both layers
awk 'BEGIN{
      VAL='$iter'*0.2*'$vval';
      XVAL=-0.09871188639278138*VAL;
      ZVAL= 0.9951160552843967*VAL;}
    {
      if(NR==2)
      {
        printf("%lf %lf %lf %lf %lf %lf\n", $1, $2, $3+VAL, $4, $5, $6)
      }else
      {
        if($4 > 9.8)
        {
          if(($1=="K")||($1=="Gh"))
          {
            printf("%s %lf %lf %lf\n", $1, $2+XVAL/4.0, $3, $4+ZVAL/4.0)
          } else
          {
            printf("%s %lf %lf %lf\n", $1, $2+XVAL/2.0, $3, $4+ZVAL/2.0)
          }
        }else
        {
          if(($1=="K")||($1=="Gh"))
          {
            printf("%s %lf %lf %lf\n", $1, $2-XVAL/4.0, $3, $4-ZVAL/4.0)
          } else
          {
            print $0
          }
        }
      }

    }
    ' USETHIS-6by4by2_structure-Si2Al.xyz > 6by4by1_structure-Si2Al-$iter.xyz
###

create_structfile()
{
  seedforfile=1
  filename="USETHIS-6by4by2_structure-Si2Al.xyz"
  if [ ! -z "$1" ]
  then
    seedforfile=$1
  fi
  if [ ! -z "$2" ]
  then
    filename=$2
  fi
  echo $seedforfile
  lbnl_processor_latest_exec.out convert_VESTA filename 6by4by2_structure-Si2Al.xyz make_illite keep_ghosts CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.make rand_seed $seedforfile SAVE_LAMMPS CHARGE MOLECULE > out.out
  cp dat_VESTA.20.xyz $filename

  awk '{if(NR==1) print $0}' $filename > modif-$filename
  awk '{if(NR==2) print $0}' 6by4by2_structure-Si2Al.xyz >> modif-$filename
  awk '{if(NR>2) print $0}' USETHIS-6by4by2_structure-Si2Al.xyz >> modif-$filename
  mv modif-$filename $filename
}
######

if [ -d lammps_files ]
then
  rm -rf lammps_files
fi
mkdir lammps_files

vval=1
initval=-2.0
for itermain in {1..20}
do
  create_structfile $itermain
  mkdir lammps_files_$itermain
  for iter in `seq 0 2 60`
  do

    awk 'BEGIN{
          VAL='$iter'*0.1*'$vval'+'$initval';
          XVAL=-0.09871188639278138*VAL;
          ZVAL= 0.9951160552843967*VAL;}
        {
          if(NR==2)
          {
            printf("%lf %lf %lf %lf %lf %lf\n", $1, $2, $3+VAL, $4, $5, $6)
          }else
          {
            if($4 > 9.8)
            {
              if(($1=="K")||($1=="Gh"))
              {
                printf("%s1 %lf %lf %lf\n", $1, $2, $3, $4)
              } else
              {
                print $0
              }
            }else
            {
              if(($1=="K")||($1=="Gh"))
              {
                printf("%s %lf %lf %lf\n", $1, $2-XVAL/2.0, $3, $4-ZVAL/2.0)
              } else
              {
                print $0
              }
            }
          }

        }
        ' USETHIS-6by4by2_structure-Si2Al.xyz > 6by4by1_structure-Si2Al-$iter.xyz
    lbnl_processor_latest_exec.out convert_VESTA filename 6by4by1_structure-Si2Al-$iter.xyz CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.make-cs-k1gh1 rand_seed $itermain SAVE_LAMMPS CHARGE MOLECULE > out.$iter 2>&1
    mv dat_lammps.20 lammps_files/dat_lammps.$iter
    rm dat_VESTA.20.xyz
  done
  mv lammps_files/* lammps_files_$itermain/
done


## then run lammps on each for each cs concentration
for rootfile in {1..20}
do
  if [ -d r$rootfile ]
  then
  rm -rf r$rootfile
  fi
  mkdir r$rootfile
  sed -e 's/SEED/'$rootfile'/' /Users/KedarKolluri/Documents/projects/LBNL/expts/scripts/scripts_diff_widths/in.addcesium_T > r$rootfile/in.addcesium_template;
  cd r$rootfile
  for file in `seq 0 10 101`
  do
    echo $file
    mkdir cs$file
    sed -e 's/GFT/'$file'/' in.addcesium_template > cs$file/in.addcesium
    cd cs$file
    pwd
    if [ -e en.output ]
    then
      rm en.output
    fi
    for file2 in `seq 0 2 41`
    do
      cp ../../prelim_single_many_random/lammps_files_1/dat_lammps.$file2 dat_lammps.00
      if [ -e dat_lammps.00 ]
      then
        lmp_git_openmpi_021415 -in in.addcesium -screen none -log log.$file2
        awk '{if($1==40000) printf("%d %lf %lf %lf %lf\n", '$file2', $3, $4, $5, $6)}' log.$file2 >> en.output
        mv dat.40000.gz dat.$file2.gz;
      fi
    done
    cd ../
  done
  cd ../
done

## for 0 and 100 only
for folder in `seq 0 100 10`
do
  foldername=cs$folder-reps
  if [ -d $foldername ]
  then
    rm -rf $foldername/
  fi
  mkdir -p $foldername
  cd $foldername

  for file in `seq 1 1 20`
  do
    echo $file
    mkdir r$file
    cp /Users/KedarKolluri/Documents/projects/LBNL/expts/scripts/scripts_diff_widths/in.addcesium_K1G1_${folder}Cs r$file/in.addcesium_K1G1
    cd r$file
    pwd
    if [ -e en.output ]
    then
      rm en.output
    fi
    for file2 in `seq 0 2 40`
    do
      cp ../../prelim_single_many_random/lammps_files_$file/dat_lammps.$file2 dat_lammps.00
      if [ -e dat_lammps.00 ]
      then
        lmp_git_openmpi_021415 -in in.addcesium_K1G1 -screen none -log log.$file2
        awk '{if($1==40000) printf("%d %lf %lf %lf %lf\n", '$file2', $3, $4, $5, $6)}' log.$file2 >> en.output
        mv dat.40000.gz dat.$file2.gz;
      fi
    done
    cd ../
  done
  cd ../
done

### postprocessing

# intermediate postprocessing for 0 and 100 only
mkdir cs0-100
cd cs0-100
for file in {1..20}; do mkdir -p r$file/cs0; mkdir -p r$file/cs100; cp ../cs0-reps/r$file/* r$file/cs0/; cp ../cs100-reps/r$file/* r$file/cs100/; done;
cd ../
##

## postprocessing
for file in {1..20}
do
  if [ -d r$file ]
  then
    for file2 in `seq 0 10 101`
    do
      if [ -d r$file/cs$file2 ]
      then
        touch tmp.cs$file2
        awk '{printf("%d %lf %lf\n", $1, $4, $5)}' r$file/cs$file2/en.output > tmp.data
        paste tmp.data tmp.cs$file2 > data.cs$file2
        cp data.cs$file2 tmp.cs$file2
      fi
    done
  fi
done
rm tmp.*
for file in `seq 0 10 101`
do
  if [ -e data.cs$file ]
  then
    awk 'BEGIN{init=0}
        {

          sum = 0; sumsq = 0;count = 0;

          for(i = 2; i <=NF; i=i+3)
          {
            sum = sum + $i;
            sumsq = sumsq + $i*$i;
            count = count + 1;
          }
          if(NR==1) init = sum/count
          if(count > 1)
          {
            printf("%lf %lf %lf\n", $1, sum/count-init, sqrt(sumsq-(sum*sum/count))/(count-1))
          }else
          {
            printf("%lf %lf %lf\n", $1, sum/count-init, 0)
          }

        }' data.cs$file > collate.data.$file
  fi
done
