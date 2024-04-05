#!/usr/bin/env python

import os
import sys
from Bio import SeqIO
import pandas as pd


def get_influenza_B_metadata(excel):
    metadata = pd.read_excel(
        excel, usecols=["Isolate_Id", "Isolate_Name", "Subtype", "Lineage"]
    )
    metadata_B = metadata[metadata["Subtype"] == "B"]
    # potential check: isolate_name[0] == subtype[0]

    return dict(zip(metadata_B["Isolate_Id"], metadata_B["Lineage"]))


def read_header_list(txt):
    header_list = []
    with open(txt, "r") as txt_file:
        for line in txt_file:
            header_list.append(line.strip())
    return header_list


def rename_header(fasta, metadata_B_dict, reverse_complementary_headers):
    renamed_fastas = []

    for record in SeqIO.parse(fasta, "fasta"):
        number, segment, isolate_name, isolate_id, empty, subtype = record.id.split("|")

        assert isolate_name[0] == subtype[0]
        assert isolate_name[0] in ["A", "B"]
        assert empty == ""
        assert segment in ["HA", "MP", "NA", "NP", "NS", "PA", "PA", "PB1", "PB2"]

        if isolate_name[0] == "A":
            kraken = "kraken:taxid|11320"
            lineage = ""
        elif isolate_name[0] == "B":
            kraken = "kraken:taxid|11520"
            lineage = (
                metadata_B_dict[isolate_id] if isolate_id in metadata_B_dict else ""
            )

        if record.id in reverse_complementary_headers:
            direction = "rc"
        else:
            direction = "f"

        renamed_header = f"{kraken}_{isolate_name}|{lineage}|{isolate_id}|{direction}|{subtype}|{segment}"
        record.id = renamed_header
        record.description = renamed_header
        renamed_fastas.append(record)

    SeqIO.write(renamed_fastas, f"{os.path.basename(fasta)}_renamed.fasta", "fasta")


if __name__ == "__main__":
    fasta = sys.argv[1]
    metadata = sys.argv[2]
    reverse_complementary_headers = sys.argv[3]
    rename_header(
        fasta,
        get_influenza_B_metadata(metadata),
        read_header_list(reverse_complementary_headers),
    )
