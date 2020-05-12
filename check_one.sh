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