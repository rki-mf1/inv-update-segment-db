#!/usr/bin/env python

import sys
from Bio import SeqIO


def get_segment_from_fasta_header(
    fasta_header,
    sep="|",
    segment_set=set(["HA", "MP", "NA", "NP", "NS", "PA", "PB1", "PB2"]),
):
    header_fields_set = set(fasta_header.split(sep))
    segment = segment_set & header_fields_set

    assert len(segment) == 1

    return list(segment)[0]


def split_by_segment(fasta):
    fastas_per_segment_dict = {
        "HA": [],
        "MP": [],
        "NA": [],
        "NP": [],
        "NS": [],
        "PA": [],
        "PB1": [],
        "PB2": [],
    }

    for record in SeqIO.parse(fasta, "fasta"):
        segment = get_segment_from_fasta_header(record.id)

        fastas_per_segment_dict[segment].append(record)

    for segment in fastas_per_segment_dict:
        SeqIO.write(fastas_per_segment_dict[segment], f"{segment}.fasta", "fasta")


if __name__ == "__main__":
    fasta = sys.argv[1]
    split_by_segment(fasta)
