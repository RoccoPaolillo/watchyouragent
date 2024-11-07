library(tidyr)
library(purrr)
library(dplyr)
library(stringr)
library(data.table)
library(readr)
library(writexl)
library(stringr)

# data preparation ###########

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

## ABM



setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/GENOVA_wya/archiviati/GE01")

GE00_azzurro_capital <- read.csv("GE01_azzurro_capital.csv", header=FALSE, sep=",")
colnames(GE00_azzurro_capital) <- c(0:35)

str_split("GE00_azzurro_capital", "_")[[1]][3]

GE00_azzurro_capital$turn <- str_split(deparse(substitute(GE00_azzurro_capital)), "_")[[1]][1]
GE00_azzurro_capital$color <- str_split(deparse(substitute(GE00_azzurro_capital)), "_")[[1]][2]
GE00_azzurro_capital$variable <- str_split(deparse(substitute(GE00_azzurro_capital)), "_")[[1]][3]

files <- list.files(pattern = ".*csv")

results = list()
for (t in files) {
 p <- read.csv(t, header=FALSE, sep=",")
 
 p$turn <- str_split(t, "_")[[1]][1]
 p$color <- str_split(t, "_")[[1]][2]
 p$variable <- str_remove(str_split(t, "_")[[1]][3],".csv")
 results[[t]] = p
}
results
df <- bind_rows(results)



