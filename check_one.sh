for i in 1 11 {3..8}; do
cat -> s2_CWP_${i} << EOF
#!/bin/bash
#SBATCH --account=def-ldiatc
#SBATCH --mail-user=vivek.verma@mail.mcgill.ca
#SBATCH --mail-type=ALL
#SBATCH --ntasks-per-node=40
#SBATCH --ntasks=40
#SBATCH --mem-per-cpu=4G
#SBATCH --time=47:58:00
module load gcc/7.3.0 r/3.6.1
/home/vivek22/R/x86_64-pc-linux-gnu-library/3.6/SAIGE/extdata/step2_SPAtests.R  --vcfFile=${i}.vcf.gz --vcfFileIndex=${i}.vcf.gz.tbi  --chrom=${i}  --vcfField=GT  --sampleFile=./id  --GMMATmodelFile=out1_CWP_${i}.rda  --varianceRatioFile=out1_CWP_${i}.varianceRatio.txt  --SAIGEOutputFile=out1_CWP_${i}_30markers.SAIGE.results.txt
EOF
done

for i in 1 11 {3..8}; do
sbatch s2_CWP_${i}
done

