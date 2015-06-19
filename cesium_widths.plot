set xtics 0.2
set key top left
set grid
set xrange[*:2.6]
plot 'positive/cs0-100/collate.data.0' using ($1/10):2:(2*$3) w yerrorbars lt -1 pt 7 ps 1 title ''
replot 'positive/cs0-100/collate.data.0'  using  ($1/10):2 smooth csplines lt -1 title 'Cs=0'

replot 'positive/collate.data.10' using ($1/10):2:(2*$3) w yerrorbars lt 7 pt 7 ps 1 title ''
replot 'positive/collate.data.10'  using  ($1/10):2 smooth csplines lt 7 title 'Cs=0.1'

replot 'positive/collate.data.20' using  ($1/10):2:(2*$3) w yerrorbars lt 2 pt 7 ps 1 title ''
replot 'positive/collate.data.20' using  ($1/10):2 smooth csplines  lt 2 title 'Cs=0.2'


replot 'positive/collate.data.40' using  ($1/10):2:(2*$3) w yerrorbars lt 3 pt 7 ps 1 title ''
replot 'positive/collate.data.40' using  ($1/10):2 smooth csplines  lt 3 title 'Cs=0.4'

replot 'positive/collate.data.50' using  ($1/10):2:(2*$3) w yerrorbars lt 6 pt 7 ps 1 title ''
replot 'positive/collate.data.50' using  ($1/10):2 smooth csplines  lt 6 title "Cs=0.5"

replot 'positive/collate.data.60' using  ($1/10):2:(2*$3) w yerrorbars lt 4 pt 7 ps 1 title ''
replot 'positive/collate.data.60' using  ($1/10):2 smooth csplines  lt 4 title "Cs=0.6"

replot 'positive/collate.data.70' using  ($1/10):2:(2*$3) w yerrorbars lt 8 pt 7 ps 1 title ''
replot 'positive/collate.data.70' using  ($1/10):2 smooth csplines  lt 8 title 'Cs=0.7'

replot 'positive/collate.data.80' using  ($1/10):2:(2*$3) w yerrorbars lt 5 pt 7 ps 1 title '' #axes x1y2
replot 'positive/collate.data.80' using  ($1/10):2 smooth csplines  lt 5 title 'Cs=0.8' #axes x1y2

replot 'positive/collate.data.90' using  ($1/10):2:(2*$3) w yerrorbars lt 9 pt 7 ps 1 title ''
replot 'positive/collate.data.90' using  ($1/10):2 smooth csplines  lt 9 title 'Cs=0.9'

replot 'positive/cs0-100/collate.data.100' using  ($1/10):2:(2*$3) w yerrorbars lt 1 pt 7 ps 1 title '' #axes x1y2
replot 'positive/cs0-100/collate.data.100' using  ($1/10):2 smooth csplines  lt 1 title 'Cs=1.0' #axes x1y2


#for file in `seq 10 10 90`; do awk '{print '$file' " " $2}' collate.data.$file | sort -n | awk '{if(NR==1) print $0}'; done;

a=3.931110 #0
b=5.148131 #10
a=-9.631192 #20
a=-12.954485 #30
a=-17.950246 #40
a=-25.202008 #50
a=-29.018238 #60
a=-33.815977 #70
a=-38.356908 #80
a=-40.522592 #90
a=-48.720690 #100

set xtics 0.4
set key top left
set grid
set xrange[*:*]
set yrange[*:1]

a=3.931110
plot 'positive/cs0-100/collate.data.0' using ($1/10):($2/a):(2*$3/a) w yerrorbars lt -1 pt 7 ps 1 title ''
replot 'positive/cs0-100/collate.data.0'  using  ($1/10):($2/a) with l lt -1 title 'Cs=0'

b=5.148131
replot 'positive/collate.data.10' using ($1/10):($2/b):(2*$3/b) w yerrorbars lt 7 pt 7 ps 1 title ''
replot 'positive/collate.data.10'  using  ($1/10):($2/b) with l lt 7 title 'Cs=0.1'

c=9.631192 #20
replot 'positive/collate.data.20' using  ($1/10):($2/c):(2*$3/c)w yerrorbars lt 2 pt 7 ps 1 title ''
replot 'positive/collate.data.20' using  ($1/10):($2/c) with l  lt 2 title 'Cs=0.2'

d=17.950246 #40
replot 'positive/collate.data.40' using ($1/10):($2/d):(2*$3/d) w yerrorbars lt 3 pt 7 ps 1 title ''
replot 'positive/collate.data.40' using  ($1/10):($2/d)with l  lt 3 title 'Cs=0.4'

e=25.202008 #50
replot 'positive/collate.data.50' using ($1/10):($2/e):(2*$3/e) w yerrorbars lt 6 pt 7 ps 1 title ''
replot 'positive/collate.data.50' using  ($1/10):($2/e) with l  lt 6 title "Cs=0.5"

f=29.018238 #60
replot 'positive/collate.data.60' using ($1/10):($2/f):(2*$3/f) w yerrorbars lt 4 pt 7 ps 1 title ''
replot 'positive/collate.data.60' using  ($1/10):($2/f) with l  lt 4 title "Cs=0.6"

g=38.356908 #80
replot 'positive/collate.data.80' using  ($1/10):($2/g):(2*$3/g) w yerrorbars lt 5 pt 7 ps 1 title '' #axes x1y2
replot 'positive/collate.data.80' using  ($1/10):($2/g) with l  lt 5 title 'Cs=0.8' #axes x1y2

h=48.720690 #100
replot 'positive/cs0-100/collate.data.100' using  ($1/10):($2/h):(2*$3/h) w yerrorbars lt 1 pt 7 ps 1 title '' #axes x1y2
replot 'positive/cs0-100/collate.data.100' using ($1/10):($2/h) with l  lt 1 title 'Cs=1.0' #axes x1y2



replot 'negative/collate.data.0' using ($1/-10):2:(2*$3) w yerrorbars lt -1 pt 7 ps 1 title ''
replot 'negative/collate.data.0'  using  ($1/-10):2 smooth csplines lt -1 title ''

replot 'negative/collate.data.10' using ($1/-10):2:(2*$3) w yerrorbars lt 7 pt 7 ps 1 title ''
replot 'negative/collate.data.10'  using  ($1/-10):2 smooth csplines lt 7 title ''

replot 'negative/collate.data.20' using  ($1/-10):2:(2*$3) w yerrorbars lt 2 pt 7 ps 1 title ''
replot 'negative/collate.data.20' using  ($1/-10):2 smooth csplines  lt 2 title ''

replot 'negative/collate.data.40' using  ($1/-10):2:(2*$3) w yerrorbars lt 3 pt 7 ps 1 title ''
replot 'negative/collate.data.40' using  ($1/-10):2 smooth csplines  lt 3 title ''

replot 'negative/collate.data.50' using  ($1/-10):2:(2*$3) w yerrorbars lt 6 pt 7 ps 1 title ''
replot 'negative/collate.data.50' using  ($1/-10):2 smooth csplines  lt 6 title ''

replot 'negative/collate.data.60' using  ($1/-10):2:(2*$3) w yerrorbars lt 4 pt 7 ps 1 title ''
replot 'negative/collate.data.60' using  ($1/-10):2 smooth csplines  lt 4 title ''


replot 'negative/collate.data.80' using  ($1/-10):2:(2*$3) w yerrorbars lt 5 pt 7 ps 1 title '' #axes x1y2
replot 'negative/collate.data.80' using  ($1/-10):2 smooth csplines  lt 5 title '' #axes x1y2

replot 'negative/collate.data.100' using  ($1/-10):2:(2*$3) w yerrorbars lt 1 pt 7 ps 1 title '' #axes x1y2
replot 'negative/collate.data.100' using  ($1/-10):2 smooth csplines  lt 1 title '' #axes x1y2







for filea in `seq 2 2 24`
do
  if [ -d $filea ]
  then
    cd $filea
    echo $filea
    gunzip dat.*.gz
    mkdir -p data/
    awk '{if(NR<10) print $0}' dat.100000 > data/header.data
    for file in dat.*
    do
      awk '{if(NR >9) print $0}' $file | sort -n > data/tmp.data
      cat data/header.data > data/$file
      cat data/tmp.data >> data/$file
      rm data/tmp.data
    done
    gzip dat.*
    cd data/
    gzip dat.*
    cd ../
    cd ../
  fi
done


set xrange[100000:]
a=8
plot '0/log.lammps' using 1:a w l title '0', '2/log.lammps' using 1:a w l title '2', '4/log.lammps' using 1:a w l title '4', '6/log.lammps' using 1:a w l title '6', '8/log.lammps' using 1:a w l title '8', '10/log.lammps' using 1:a w l title '10', '12/log.lammps' using 1:a w l title '12', '14/log.lammps' using 1:a w l title '14', '16/log.lammps' using 1:a w l title '16', '18/log.lammps' using 1:a w l title '18', '20/log.lammps' using 1:a w l title '20'


replot '2/log.lammps' using 1:a w l title '2', '6/log.lammps' using 1:a w l title '6', '10/log.lammps' using 1:a w l title '10', '14/log.lammps' using 1:a w l title '14', '18/log.lammps' using 1:a w l title '18', '22/log.lammps' using 1:a w l title '22', '28/log.lammps' using 1:a w l title '28'


lbnl_processor_latest_exec.out convert_VESTA filename 6by4by1_structure-Si2Al.xyz make_illite keep_ghosts CUTOFF_FILE /Users/KedarKolluri/lib/cutoff_file.illite.make-cs rand_seed 1 SAVE_LAMMPS CHARGE MOLECULE > out.1 2>&1
