#!/bin/bash
# this script is for HPC (Beluga.computecanada.ca)
mkdir /scratch/vivek22/FM_UKB/FM2
cd /scratch/vivek22/FM_UKB/FM2 || exit
# transfer sample and UKB_pheno.tab (made using data_wrangling.R) files using Globus
# make plink files from bgen files:
for i in {1..22} X; do
cat -> geno_qc_${i} << EOF
#!/bin/bash
#SBATCH --account=def-ldiatc
#SBATCH --mail-user=vivek.verma@mail.mcgill.ca
#SBATCH --mail-type=ALL
#SBATCH --cpus-per-task=40
#SBATCH --mem-per-cpu=4G
#SBATCH --time=28:00:00

/home/vivek22/qctool/build/release/qctool_v2.0.7 \
-g ~/projects/def-ldiatc/uk_biobank/${i}.bgen \
-s ~/projects/def-ldiatc/uk_biobank/${i}.sample \
-incl-samples /scratch/vivek22/FM_UKB/FM2/sample \
-og chr_${i} \
-ofiletype binary_ped \
-threads 40
EOF
done
for i in {1..22} X; do
sbatch geno_qc_${i}
done
# next steps have dependence as follows:
# 1.  SAIGE step 1 (for FM)
# 2.  SAIGE step 1 (for CWP)
# 3a. make .vcf -> 3b. make .vcf.gz -> .vcf.gz.tbi (needed for saige step 2)
# 4.  make id file
# 5.  SAIGE step 2 (for FM)
# 6.  SAIGE step 2 (for CWP)

# 1. ***************************** SAIGE STEP1 (for FM) ********************************* #
for i in {22..1} X; do
cat -> s1_FM_${i} << EOF
#!/bin/bash
#SBATCH --account=def-ldiatc
#SBATCH --mail-user=vivek.verma@mail.mcgill.ca
#SBATCH --mail-type=ALL
#SBATCH --cpus-per-task=40
#SBATCH --mem-per-cpu=4G
#SBATCH --time=48:00:00

module load gcc/7.3.0 r/3.6.1
/home/vivek22/R/x86_64-pc-linux-gnu-library/3.6/SAIGE/extdata/step1_fitNULLGLMM1.R \
        --plinkFile=./chr_${i} \
        --phenoFile=./UKB_pheno.tab \
        --phenoCol=FM \
        --covarColList=AGE,UKBL,PC1,PC2,PC3,PC4 \
        --sampleIDColinphenoFile=IID \
        --traitType=binary        \
        --outputPrefix=out1_FM_${i} \
        --nThreads=40 \
        --LOCO=FALSE
EOF
done

for i in {22..1} X; do
sbatch s1_FM_${i}
done

# fix chr_X.bim: replace X with 23
awk -v var="23" -F" " 'BEGIN {OFS = FS} {$1 = var; print}' < chr_X.bim > 23.bim
cp chr_X.bed 23.bed; cp chr_X.fam 23.fam



# 2. ***************************** SAIGE STEP1 (for CWP) ********************************* #
for i in {23..1} ; do
cat -> s1_CWP_${i} << EOF
#!/bin/bash
#SBATCH --account=def-ldiatc
#SBATCH --mail-user=vivek.verma@mail.mcgill.ca
#SBATCH --mail-type=ALL
#SBATCH --cpus-per-task=40
#SBATCH --mem-per-cpu=4G
#SBATCH --time=48:00:00

module load gcc/7.3.0 r/3.6.1
/home/vivek22/R/x86_64-pc-linux-gnu-library/3.6/SAIGE/extdata/step1_fitNULLGLMM1.R \
        --plinkFile=./chr_${i} \
        --phenoFile=./UKB_pheno.tab \
        --phenoCol=CWP \
        --covarColList=AGE,UKBL,PC1,PC2,PC3,PC4 \
        --sampleIDColinphenoFile=IID \
        --traitType=binary        \
        --outputPrefix=out1_CWP_${i} \
        --nThreads=40 \
        --LOCO=FALSE
EOF
done

for i in {23..1} ; do
sbatch s1_CWP_${i}
done

# 3. ***####***####*** make vcf, vcf.gz and vcf index files ***####***####*** 

for i in {23..1} ; do
cat -> vcf_${i} << EOF
#!/bin/bash
#SBATCH --account=def-ldiatc
#SBATCH --mail-user=vivek.verma@mail.mcgill.ca
#SBATCH --mail-type=ALL
#SBATCH --cpus-per-task=40
#SBATCH --mem-per-cpu=4G
#SBATCH --time=12:00:00
module load plink/2.00-10252019-avx2
plink2 --bfile /scratch/vivek22/FM_UKB/FM2/chr_${i} --recode vcf --out ${i}
module load bcftools/1.10.2
module load mugqic/tabix
bcftools view -Oz --no-version --threads 40 ${i}.vcf > ${i}.vcf.gz
tabix -p vcf ${i}.vcf.gz
EOF
done
for i in {23..1} ; do
sbatch vcf_${i}
done

# make ID file from fam
# confirm if all fam has same number of IDs:
cd /scratch/vivek22/FM_UKB/FM2
wc -l chr_*.fam
awk '{print $2}' < chr_1.fam > id

# ***************************** SAIGE STEP2 FM ********************************* #

cd /scratch/vivek22/FM_UKB/FM2
for i in {1..23}; do
cat -> s2_FM_${i} << EOF
#!/bin/bash
#SBATCH --account=def-ldiatc
#SBATCH --mail-user=vivek.verma@mail.mcgill.ca
#SBATCH --mail-type=ALL
#SBATCH --ntasks-per-node=40
#SBATCH --ntasks=40
#SBATCH --mem-per-cpu=3G
#SBATCH --time=23:58:00
module load gcc/7.3.0 r/3.6.1
/home/vivek22/R/x86_64-pc-linux-gnu-library/3.6/SAIGE/extdata/step2_SPAtests.R  --vcfFile=${i}.vcf.gz --vcfFileIndex=${i}.vcf.gz.tbi  --chrom=${i}  --vcfField=GT  --sampleFile=./id  --GMMATmodelFile=out1_FM_${i}.rda  --varianceRatioFile=out1_FM_${i}.varianceRatio.txt  --SAIGEOutputFile=out1_FM_${i}_30markers.SAIGE.results.txt 
EOF
done
for i in {1..23}; do
sbatch s2_FM_${i}
done

# ***************************** SAIGE STEP2 CWP ********************************* #

cd /scratch/vivek22/FM_UKB/FM2
for i in {1..23}; do
cat -> s2_CWP_${i} << EOF
#!/bin/bash
#SBATCH --account=def-ldiatc
#SBATCH --mail-user=vivek.verma@mail.mcgill.ca
#SBATCH --mail-type=ALL
#SBATCH --ntasks-per-node=40
#SBATCH --ntasks=40
#SBATCH --mem-per-cpu=4G
#SBATCH --time=23:58:00
module load gcc/7.3.0 r/3.6.1
/home/vivek22/R/x86_64-pc-linux-gnu-library/3.6/SAIGE/extdata/step2_SPAtests.R  --vcfFile=${i}.vcf.gz --vcfFileIndex=${i}.vcf.gz.tbi  --chrom=${i}  --vcfField=GT  --sampleFile=./id  --GMMATmodelFile=out1_CWP_${i}.rda  --varianceRatioFile=out1_CWP_${i}.varianceRatio.txt  --SAIGEOutputFile=out1_CWP_${i}_30markers.SAIGE.results.txt 
EOF
done
for i in {1..23}; do
sbatch s2_CWP_${i}
done

# to-do:
# sbatch s2_FM_X; sbatch s2_CWP_X
















