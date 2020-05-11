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
#--------------------------------------------------------------------
########### make vcf and vcf index files ##################:
mkdir /scratch/vivek22/FM_UKB/geno/vcf
cd /scratch/vivek22/FM_UKB/geno/vcf

for i in {1..22}; do
cat -> vcf_${i} << EOF
#!/bin/bash
#SBATCH --account=def-ldiatc
#SBATCH --mail-user=vivek.verma@mail.mcgill.ca
#SBATCH --mail-type=ALL
#SBATCH --cpus-per-task=40
#SBATCH --mem-per-cpu=4G
#SBATCH --time=00:60:00
module load plink/2.00-10252019-avx2
plink2 --bfile /scratch/vivek22/FM_UKB/geno/qc_snp/chr_${i} --recode vcf --out ${i}
EOF
done
for i in {1..22}; do
sbatch vcf_${i}
done

for i in {1..22}; do
cat -> vcf_gz_${i} << EOF
#!/bin/bash
#SBATCH --account=def-ldiatc
#SBATCH --mail-user=vivek.verma@mail.mcgill.ca
#SBATCH --mail-type=ALL
#SBATCH --ntasks-per-node=40
#SBATCH --ntasks=40
#SBATCH --mem-per-cpu=4G
#SBATCH --time=04:00:00

module load bcftools/1.10.2
module load mugqic/tabix
bcftools view -Oz --no-version --threads 40 ${i}.vcf > ${i}.vcf.gz
tabix -p vcf ${i}.vcf.gz
EOF
done

for i in {1..12}; do
sbatch vcf_gz_${i}
done

# make ID file from fam
# confirm if all fam has same number of IDs:
wc -l ../qc_snp/chr_*.fam
cat ../qc_snp/chr_1.fam | awk '{print $2}' > id