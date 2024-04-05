#!/usr/bin/env Rscript

library(seqinr)
library(data.table)

args <- commandArgs(TRUE)
name <- args[1]
fasta <- args[2]
stats <- args[3]

# v1 ID
# v2 length
# v3 count ambiguous bases
# v4 %not valid characters
# v5 %ambiguous bases

segment <- fread(file = stats, header = FALSE, sep = "\t", fill = TRUE)
# extract only the sequences that are not to short/long
segment_good_len <- segment[which(segment$V2 >= (median(segment$V2) - 200) & segment$V2 <= (median(segment$V2) + 200)), ]
# extract only sequences with less than 5% ambiguous bases
segment_good_len_fewAmbig <- segment_good_len[which(segment_good_len$V5 <= 5), ]
# remove sequences with wrong characters
segment_good_len_fewAmbig_goodqual <- segment_good_len_fewAmbig[which(segment_good_len_fewAmbig$V4 <= 0), ]

# read in coresponding fasta file
fastain <- read.fasta(fasta)
fastaout <- fastain[c(which(names(fastain) %in% segment_good_len_fewAmbig_goodqual$V1))]

# export short fasta
write.fasta(fastaout, names = names(fastaout), file.out = paste0(name, "_fewAmbig-corLen.fasta"))
