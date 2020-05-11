options(digits = 2)
options(device = RStudioGD)
# get sample QC (sqc) data:
sqc <- read.table("S:/UKB-pheno/ukb_sqc_v2.txt", quote = "\"", comment.char = "")
for (i in 1:40) {
    names(sqc)[i + 25] <- paste0("PC",i)
}
sqc <- sqc[,-c(1,2,4:9,12:18,21,22,25,66:68)]
names(sqc)[1:7] <- c("array","sex","inf_sex","het_miss_outlr","sex_aneup","exces_relatvs","white_brit")
length(which(sqc$sex != sqc$inf_sex)) # 378 IDs sex mismatch
sqc$sex_discord <- as.numeric(sqc$sex != sqc$inf_sex)
sqc <- sqc[,c(1:3,48,4:47)]
IID <- read.table("S:/UKB-pheno/1.fam", quote = "\"", comment.char = "")
length(which(IID$V1 != IID$V2)) # 0
IID <- IID[,1]
sqc <- cbind(IID,sqc)
sapply(sqc[,c(5:8)], function(y) summary(as.factor(y)))

#   sex_discord het_miss_outlr sex_aneup exces_relatvs
# 0      487999         487409    487725        488189
# 1         378            968       652           188

sqc[5:9] <- lapply(sqc[5:9], factor)
# add age
age <- read.table("S:/UKB-pheno/age.tsv", quote = "\"", comment.char = "", header = T)
names(age) <- c("IID","AGE")
sqc <- merge(age, sqc, by = "IID", all.y = T)
sapply(sqc, function(y) sum(is.na(y))) # 14 NAs for age
# impute missing AGE values with median age (58 years)
sqc$AGE[is.na(sqc$AGE)] <- median(sqc$AGE, na.rm = T)
saveRDS(sqc,"UKB_cov.RDS")

### FM - specific cleaning
# general cleaning dropped 1999 IIDs
df <- subset(sqc, sex_discord == 0 & het_miss_outlr == 0 & sex_aneup == 0 & exces_relatvs == 0)
df <- df[,-c(5:9)]
df$array <- as.numeric(ifelse(df$array == "UKBL", 1, 0))
df$sex <- as.numeric(ifelse(df$sex == "M", 1, 0))
names(df)[3:4] <- c("UKBL","MALE")
# drop negative IIDs:
df <- df[df$IID > 0,]
cntrl <- scan("S:/UKB-pheno/cntrl", what = "integer", quiet = F)
fm <- scan("S:/UKB-pheno/fm", what = "integer", quiet = F)
cwp <- scan("S:/UKB-pheno/pain", what = "integer", quiet = F)
df$FM <- ifelse(df$IID %in% fm, 1, ifelse(df$IID %in% cntrl, 0, NA))
df$CWP <- ifelse(df$IID %in% cwp, 1, ifelse(df$IID %in% cntrl, 0, NA))
df <- df[df$MALE == 0, -c(4)]
# would dropping non-whites improve case : cntrl imbalance?
prop.table(table(df$FM,df$white_brit))*100
#      0    1
# 0 14.1 84.5
# 1  0.2  1.1
prop.table(table(df$CWP,df$white_brit))*100
#      0    1
# 0 13.6 81.5
# 1  1.1  3.9

# in other words, I will lose only 1153 out of 5220 CWP IIDs, and
# 235 out of 1403 FM IIDs if I limit analysis to white brits only.
# I can limit PCs to 1-4 as future analysis will be ethnically limited to whites
df <- df[df$white_brit == 1, -c(4)]
# missing values for CWP (also missing for FM) dropped (n = 130655)
sum(length(df$IID[is.na(df$CWP & is.na(df$FM))]))
df <- df[!is.na(df$CWP),c(1:7,44,45)]
### --- Final dataframe: 89956 x 9 --- ###
write.table(df, file = "UKB_pheno.tab", append = F, quote = F, sep = "\t",
            eol = "\n", na = "NA", dec = ".", row.names = F, col.names = T)
# make clean sample file
sam <- IID[IID %in% df$IID]
write.table(sam, file = "sample", append = F, quote = F, sep = "\t",
            eol = "\n", na = "NA", dec = ".", row.names = F, col.names = F)
rm(list = setdiff(ls(), "df")); gc()



