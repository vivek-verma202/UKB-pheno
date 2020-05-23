#!/bin/bash
module load gcc/7.3.0 r/3.6.1
/home/vivek22/R/x86_64-pc-linux-gnu-library/3.6/SAIGE/extdata/step1_fitNULLGLMM1.R \
        --plinkFile=./chr_22 \
        --phenoFile=./UKB_pheno.tab \
        --phenoCol=FM \
        --covarColList=AGE,UKBL,PC1,PC2,PC3,PC4 \
        --sampleIDColinphenoFile=IID \
        --traitType=binary        \
        --outputPrefix=out1_FM_22 \
        --nThreads=40 \
        --LOCO=FALSE

for i in {22..1} X; do
echo s1_FM_${i}
done

cat -> s2_FM_1 << EOF
#!/bin/bash
#SBATCH --account=def-ldiatc
#SBATCH --mail-user=vivek.verma@mail.mcgill.ca
#SBATCH --mail-type=ALL
#SBATCH --ntasks-per-node=40
#SBATCH --ntasks=40
#SBATCH --mem-per-cpu=3G
#SBATCH --time=11:58:00
module load gcc/7.3.0 r/3.6.1
/home/vivek22/R/x86_64-pc-linux-gnu-library/3.6/SAIGE/extdata/step2_SPAtests.R \
        --vcfFile=1.vcf.gz \ 
        --vcfFileIndex=1.vcf.gz.tbi \
        --chrom=1 \
        --vcfField=GT \
        --sampleFile=id \
        --GMMATmodelFile=out1_FM_1.rda \
        --varianceRatioFile=out1_FM_1.varianceRatio.txt \
        --SAIGEOutputFile=out1_FM_1_30markers.SAIGE.results.txt 
EOF
