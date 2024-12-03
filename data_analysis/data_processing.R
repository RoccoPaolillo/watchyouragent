library(tidyr)
library(purrr)
library(dplyr)
library(stringr)
library(data.table)
library(readr)
library(writexl)
library(stringr)
library(readxl)

## Merge dataset ####

genova <- read.csv("C:/Users/rocpa/OneDrive/Documenti/GitHub/tragedynatural/Genova/simulationsGE24.csv",sep=",")

genova$time <- str_remove(genova$time,"day_")
genova$time <- as.numeric(genova$time)
genova$note <- "genova"

rmBR01 <- read.csv("C:/Users/rocpa/OneDrive/Documenti/GitHub/tragedynatural/Roma_BR/BR01/simulationsBR01.csv",sep=",")
rmBR02 <- read.csv("C:/Users/rocpa/OneDrive/Documenti/GitHub/tragedynatural/Roma_BR/BR02/BR02_simulations.csv",sep=",")

df_simulations <- rbind(genova,rmBR01,rmBR02)

write.csv(df_simulations,"C:/Users/rocpa/OneDrive/Documenti/GitHub/tragedynatural/data_analysis/df_simulations.csv", 
          row.names = FALSE)


df_studenti <- read_xlsx("C:/Users/rocpa/OneDrive/Documenti/GitHub/tragedynatural/data_analysis/df_studenti.xlsx")
BR03_studenti <- read_xlsx("C:/Users/rocpa/OneDrive/Documenti/GitHub/tragedynatural/Roma_BR/BR03/BR03_studenti.xlsx")

# studentsgenova <- studentsgenova[,-49]
# BR02studenti$StartDate <- as.character(BR02studenti$StartDate)
# BR02studenti$EndDate <- as.character(BR02studenti$EndDate)

df_studenti <- rbind(df_studenti,BR03_studenti)
writexl::write_xlsx(df_studenti, "C:/Users/rocpa/OneDrive/Documenti/GitHub/tragedynatural/data_analysis/df_studenti.xlsx")

df_docenti <- read_xlsx("C:/Users/rocpa/OneDrive/Documenti/GitHub/tragedynatural/data_analysis/df_docenti.xlsx")
BR03_docenti <- read_xlsx("C:/Users/rocpa/OneDrive/Documenti/GitHub/tragedynatural/data_upload/Docenti_20241127_RM03.xlsx")
BR03_docenti$StartDate <- as.character(docentiBR03$StartDate)
BR03_docenti$EndDate <- as.character(docentiBR03$EndDate)
BR03_docenti$turn <- "BR03"
writexl::write_xlsx(BR03_docenti, "Roma_BR/BR03/BR03_docenti.xlsx")

#df_docenti$convivenza <- NA

df_docenti <- rbind(df_docenti,docentiBR03)


writexl::write_xlsx(df_docenti, "C:/Users/rocpa/OneDrive/Documenti/GitHub/tragedynatural/data_analysis/df_docenti.xlsx")


## ABM preprocess data####

setwd("C:/Users/rocpa/OneDrive/Desktop/BR02_20_11_2024/data/upload")

# farmers

files <- list.files(pattern = ".*csv")

results = list()
for (t in files) {
  p <- read.csv(t, header=FALSE, sep=",")
  
  p$turn <- str_split(t, "_")[[1]][2]
  p$color <- str_split(t, "_")[[1]][4]
  p$output <- str_remove(str_split(t, "_")[[1]][5],".csv")
  p$condition <- str_split(t,"_")[[1]][3]
  results[[t]] = p
}
results
df <- bind_rows(results)

# df$condition = "post"

filesglb <- list.files(path = "global", pattern = ".*csv")

resultglb = list()
for (glb in filesglb) {
  pglb <- read.csv(paste0("global/",glb), header=FALSE, sep=",")
  pglb$turn <- str_split(glb, "_")[[1]][2]
  pglb$color <- NA
  pglb$output <- str_remove(str_split(glb, "_")[[1]][4],".csv")
  pglb$condition <- str_split(glb, "_")[[1]][3]
  resultglb[[glb]] = pglb
}
resultglb
dfglb <- bind_rows(resultglb)
# dfglb$color <- NA
# dfglb$condition <- "post"

# merging farmers and globals
df <- rbind(df,dfglb)
upcol <- ncol(df) - 4

for (i in c(1:29)) {
  #  names(df)[i] <- paste0("day_", (i - 1))
  names(df)[i] <-  (i - 1)
  print(i - 1)
}

names(df)[34] <-  29  #in case the 2 simulations have different number of days
names(df)[35] <-  30
names(df)[36] <-  31
names(df)[37] <-  32
names(df)[38] <-  33
names(df)[39] <-  34
names(df)[40] <-  35

long_df <- pivot_longer(df,cols = c((1:29),(34:40)), names_to = c("time"), values_to = "score")



# check for names correction
#long_df[long_df$condition == "post3",]$condition <- "post"
long_df$note <- "no malus, rinnovo energetico 0.35"
write.csv(long_df,file = "final/BR02_simulations.csv", row.names = FALSE)

BR02 <- read.csv("final/BR02_simulations.csv", sep=",")

# Questionari preprocess data ####

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/tragedynatural/")

BR03_studenti <- read_xlsx("data_upload/Questionario_20241127_RM03.xlsx")
BR03_studenti$StartDate <- as.character(BR03_studenti$StartDate)
BR03_studenti$EndDate <- as.character(BR03_studenti$EndDate)
BR03_studenti$turn <- "BR03"
BR03_studenti$smartphone <- 1
BR03_studenti$colore_stringa <- "colorestringa"
BR03_studenti[BR03_studenti$colore == 1,]$colore_stringa <- "azzurro"
BR03_studenti[BR03_studenti$colore == 2,]$colore_stringa <- "blu"
BR03_studenti[BR03_studenti$colore == 3,]$colore_stringa <- "giallo"
BR03_studenti[BR03_studenti$colore == 4,]$colore_stringa <- "rosa"
BR03_studenti[BR03_studenti$colore == 5,]$colore_stringa <- "rosso"
BR03_studenti[BR03_studenti$colore == 0,]$colore_stringa <- "nullo"

writexl::write_xlsx(BR03_studenti, "Roma_BR/BR03/BR03_studenti.xlsx")






# data preparation Genova ###########

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/")

GE01 <- read.csv("GE01/questionari/Questionario_20241028_GR01.csv", header=FALSE, sep=";")
colnames(GE01) <- GE01[1,]
GE01 <- GE01[-c(1,2), ] 
GE01$turn <- "GE01"

GE02 <- read.csv("GE02/questionari/Questionario_20241029_GR02.csv", header=FALSE, sep=";")
colnames(GE02) <- GE02[1,]
GE02 <- GE02[-c(1,2), ] 
GE02$turn <- "GE02"

GE03 <- read.csv("GE03/questionari/Questionario_20241029_GR03.csv", header=FALSE, sep=";")
colnames(GE03) <- GE03[1,]
GE03 <- GE03[-c(1,2), ] 
GE03$turn <- "GE03"

GE04 <- read.csv("GE04/questionari/Questionario_20241029_GR04.csv", header=FALSE, sep=";")
GE04 <- GE04[-1,]
colnames(GE04) <- GE04[1,]
GE04 <- GE04[-c(1,2), ] 
GE04$turn <- "GE04"

genova24_studenti <- rbind(GE01,GE02,GE03,GE04)

# risposta collezionata tramite smartphone (1) o cartaceo (0). Il cartaceo caricato a mano e info missing (paradati e.g. durata e colore)
genova24_studenti$smartphone <- 1

GEcartaceo <- read.csv("ge_student_cartaceo.csv", header=FALSE, sep=";")
GEcartaceo <- GEcartaceo[-1,]
colnames(GEcartaceo) <- GEcartaceo[1,]
GEcartaceo <- GEcartaceo[-c(1,2), ] 
GEcartaceo$turn <- "GE00"
GEcartaceo[GEcartaceo$ResponseId == "R_cartaceo_1",]$turn <- "GE02"
GEcartaceo[GEcartaceo$ResponseId == "R_cartaceo_3",]$turn <- "GE02"

# risposta collezionata tramite smartphone (1) o cartaceo (0)
GEcartaceo$smartphone <- 0

genova24_studenti <- rbind(genova24_studenti,GEcartaceo)

genova24_studenti$colore_stringa <- "colorestringa"
genova24_studenti[genova24_studenti$colore == 1,]$colore_stringa <- "azzurro"
genova24_studenti[genova24_studenti$colore == 2,]$colore_stringa <- "blu"
genova24_studenti[genova24_studenti$colore == 3,]$colore_stringa <- "giallo"
genova24_studenti[genova24_studenti$colore == 4,]$colore_stringa <- "rosa"
genova24_studenti[genova24_studenti$colore == 5,]$colore_stringa <- "rosso"
genova24_studenti[genova24_studenti$colore == 0,]$colore_stringa <- "nullo"

for (i in c(18:23, 25:27,29:48)) {
  genova24_studenti[,i] <- as.integer(genova24_studenti[,i] )
}

writexl::write_xlsx(genova24_studenti, "genova24_studenti.xlsx")

# DOCENTI

docGE01 <- read.csv("GE01/questionari/Docenti_20241028_GR01.csv", header=FALSE, sep=";")
colnames(docGE01) <- docGE01[1,]
docGE01 <- docGE01[-c(1,2), ] 
docGE01$turn <- "GE01"

docGE02 <- read.csv("GE02/questionari/Docenti_20241029_GR02.csv", header=FALSE, sep=";")
colnames(docGE02) <- docGE02[1,]
docGE02 <- docGE02[-c(1,2), ] 
docGE02$turn <- "GE02"

docGE03 <- read.csv("GE03/questionari/Docenti_20241029_GR03.csv", header=FALSE, sep=";")
colnames(docGE03) <- docGE03[1,]
docGE03 <- docGE03[-c(1,2), ] 
docGE03$turn <- "GE03"

docGE04 <- read.csv("GE04/questionari/Docenti_20241029_GR04.csv", header=FALSE, sep=";")
colnames(docGE04) <- docGE04[1,]
docGE04 <- docGE04[-c(1,2), ] 
docGE04$turn <- "GE04"

genova24_docenti <- rbind(docGE01,docGE02,docGE03,docGE04)

for (i in c(18:25,30)) {
  genova24_docenti[,i] <- as.integer(genova24_docenti[,i] )
}

writexl::write_xlsx(genova24_docenti, "genova24_docenti.xlsx")

# for merging

colnames(genova24_studenti)[-50] <- paste0("stud_", colnames(genova24_studenti)[-50] )
colnames(genova24_docenti)[-33] <- paste0("doc_", colnames(genova24_docenti)[-33] )
df_genova <- merge(genova24_studenti, genova24_docenti, by = "turn")

## Rome pilot 22/10/2024
ROMEante <- read.csv("ROMA_pilot/QuestionarioExAnte_20241022.csv", header=FALSE, sep=",")
colnames(ROMEante) <- ROMEante[1,]
ROMEante <- ROMEante[-c(1:3), ] 
ROMEante$condition <- "exante"
writexl::write_xlsx(ROMEante, "ROMEante_pilot.xlsx")

ROMEpost <- read.csv("ROMA_pilot/QuestionarioExPost_20241022.csv", header=FALSE, sep=",")
colnames(ROMEpost) <- ROMEpost[1,]
ROMEpost <- ROMEpost[-c(1:3), ] 
ROMEpost$condition <- "expost"
writexl::write_xlsx(ROMEpost, "ROMEpost_pilot.xlsx")



# Compose Genova ABM####
long_df1 <- read.csv("C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/GE01/final/GE01_sim.csv",sep=",")
long_df2 <- read.csv("C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/GE02/final/GE02_sim.csv",sep=",")

long_df_fin <- rbind(long_df1,long_df2)

# ABM GE03 ####

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/GE03")

files <- list.files(pattern = ".*csv")

results = list()
for (t in files) {
  p <- read.csv(t, header=FALSE, sep=",")
  
  p$turn <- str_split(t, "_")[[1]][1]
  p$condition <- str_split(t, "_")[[1]][2]
  p$color <- str_split(t, "_")[[1]][3]
  p$output <- str_remove(str_split(t, "_")[[1]][4],".csv")
  results[[t]] = p
}
results
df <- bind_rows(results)

filesglb <- list.files(path = "global", pattern = ".*csv")

resultglb = list()
for (glb in filesglb) {
  pglb <- read.csv(paste0("global/",glb), header=FALSE, sep=",")
  pglb$turn <- str_split(glb, "_")[[1]][1]
  pglb$condition <- str_split(glb, "_")[[1]][2]
  pglb$output <- str_remove(str_split(glb, "_")[[1]][3],".csv")
  resultglb[[glb]] = pglb
}
resultglb
dfglb <- bind_rows(resultglb)
dfglb$color <- NA

df <- rbind(df,dfglb)

upcol <- ncol(df) - 4

for (i in c(1:upcol)) {
  names(df)[i] <- paste0("day_", (i - 1))
  print(i - 1)
}

long_df <- pivot_longer(df,cols = c(1:(ncol(df) - 4)), names_to = c("time"), values_to = "score")

#colnames(df) <- str_replace(colnames(df),"V","day_")
#long_df <- pivot_longer(df,cols = c(1:(ncol(df) - 4)), names_to = c("time"), values_to = "score")

write.csv(long_df,file = "final/GE03_sim.csv", row.names = FALSE)

# GE04, risenergtot for GEO4 pre condition had to be handy inserted from world output ####

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/GE04")

files <- list.files(pattern = ".*csv")

results = list()
for (t in files) {
  p <- read.csv(t, header=FALSE, sep=",")
  
  p$turn <- str_split(t, "_")[[1]][1]
  p$condition <- str_split(t, "_")[[1]][2]
  p$color <- str_split(t, "_")[[1]][3]
  p$output <- str_remove(str_split(t, "_")[[1]][4],".csv")
  results[[t]] = p
}
results
df <- bind_rows(results)

filesglb <- list.files(path = "global", pattern = ".*csv")

resultglb = list()
for (glb in filesglb[1:3]) {
  pglb <- read.csv(paste0("global/",glb), header=FALSE, sep=",")
  pglb$turn <- str_split(glb, "_")[[1]][1]
  pglb$condition <- str_split(glb, "_")[[1]][2]
  pglb$output <- str_remove(str_split(glb, "_")[[1]][3],".csv")
  resultglb[[glb]] = pglb
}
resultglb
dfglb <- bind_rows(resultglb)
dfglb$color <- NA

df <- rbind(df,dfglb)

val <- c(22050, 21668.8, 21444.8, 21277.4, 21163.8, 21099.6, 21061.4, 21053.6, 20123.6, 19614.2, 19319.8, 19254, 19376.6, 19590.8, 19890, 20159.27, 18999.78, 18028.49, 17496.49, 17340, 17449.4,
         17783, 18249.6, 15732.6, 14235.6, 13555.4, 13502.2, 14002.8, 14513, 17711.66, 15214.42, 13708.79, 13004.1, 13008.95, 13798.34, 15023.86, "GEO4","pre",NA,"risenergtot")

df <- rbind(df,val)

df[,c(1:36)] <- lapply(df[,c(1:36)], function(x) as.numeric(x))

# colnames(df) <- str_replace(colnames(df),"V","day_")
upcol <- ncol(df) - 4

for (i in c(1:upcol)) {
  names(df)[i] <- paste0("day_", (i - 1))
  print(i - 1)
}

long_df <- pivot_longer(df,cols = c(1:(ncol(df) - 4)), names_to = c("time"), values_to = "score")


write.csv(long_df,file = "final/GE04_sim.csv", row.names = FALSE)


###

long_df1 <- read.csv("C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/GE01/final/GE01_sim.csv",sep=",")
long_df2 <- read.csv("C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/GE02/final/GE02_sim.csv",sep=",")
long_df3 <- read.csv("C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/GE03/final/GE03_sim.csv",sep=",")
long_df4 <- read.csv("C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/GE04/final/GE04_sim.csv",sep=",")

long_dfGE <- rbind(long_df1,long_df2,long_df3, long_df4)

write.csv(long_dfGE,file = "C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/simulationsGE24.csv", row.names = FALSE)
long_dfGE <- read.csv("C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/simulationsGE24.csv",sep=",")











