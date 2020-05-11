#!/bin/bash
# this script is for local lab server
# make FM pheno:
cd /scratch/vverma3/UKB-pheno || exit
cut -d $'\t' -f 1,576-604,1585-1964,1993-2427 < /mnt/nfs/backup/data/uk_biobank/ukb8045.r.tab  > fm.tsv
awk -f ~/awk_ukb_pheno fm.tsv > fm.melt
awk '{if ($5 == 1542){print $1}}' fm.melt > fm_ids
grep M797 < fm.melt | awk '{print $1}' >> fm_ids
uniq fm_ids > fm_id ; rm fm_ids
# get CWP (gen pain 3+ months, Data-Field 2956)
cut -d $'\t' -f 1,261 < /mnt/nfs/backup/data/uk_biobank/ukb8045.r.tab  > cwp.tsv
awk '{if ($2 == 1){print $1}}' < cwp.tsv > cwp_id
# get controls
cut -d $'\t' -f 1,522-528 < /mnt/nfs/backup/data/uk_biobank/ukb8045.r.tab > pain.tsv
awk -f ~/awk_ukb_pheno pain.tsv > pain.melt
awk '{if ($5 == -7){print $1}}' pain.melt > cntrl_id
wc -l *id # 197152 controls, 7130 cwp, 1826 fm
awk 'NR==FNR{A[$1];next}$1 in A' fm_id cntrl_id | wc -l # 102 fm_ids in cntrl_ids
awk 'NR==FNR{A[$1];next}$1 in A' cwp_id cntrl_id | wc -l # 0 cwp_ids in cntrl_ids
awk 'NR==FNR{A[$1];next}$1 in A' cwp_id fm_id | wc -l # 694 cwp_ids in fm_ids
awk 'NR==FNR{A[$1];next}$1 in A' fm_id cwp_id | wc -l # 604 cwp_ids in fm_ids
sort fm_id > fm; sort cntrl_id > cntrl; sort cwp_id > cwp; rm fm_id cntrl_id cwp_id cwp.tsv fm.tsv fm.melt pain.tsv pain.melt
wc -l cntrl fm
comm -23 cntrl fm > f_cntrl
wc -l cntrl f_cntrl fm
mv f_cntrl cntrl # dropped 102 cntrl ids that wer in FM
cat fm cwp | sort | uniq > pain
# get age data (column 1140 has DF 21003 i.e. age information)
cut -d $'\t' -f 1,1140 < /mnt/nfs/backup/data/uk_biobank/ukb8045.r.tab > age.tsv

