#!/usr/bin/env python

import os
import sys
from Bio import SeqIO
import pandas as pd
import re


def get_segment_from_fasta_header(
    fasta_header,
    sep="|",
    segment_set=set(["HA", "MP", "NA", "NP", "NS", "PA", "PB1", "PB2"]),
):
    header_fields_set = set(fasta_header.split(sep))
    segment = segment_set & header_fields_set
    assert len(segment) == 1
    return list(segment)[0]


def get_isolateid_from_fasta_header(
    fasta_header,
    sep="|",
    pattern=r"^EPI_ISL_\d+$",
):
    isolate_id = None
    for field in fasta_header.split(sep):
        if re.fullmatch(pattern, field):
            isolate_id = field
    return isolate_id


def get_metadata_from_excel(excel):
    metadata = pd.read_excel(
        excel, usecols=["Isolate_Id", "Isolate_Name", "Subtype", "Lineage"]
    )
    return metadata


def get_field_value(df: pd.DataFrame, isolate_id: str, field_name: str):
    """
    Retrieve a field value from a DataFrame where Isolate_Id matches.

    Args:
        df (pd.DataFrame): Input DataFrame
        isolate_id (str): Value to match in Isolate_Id column
        field_name (str): Name of the column whose value to retrieve

    Returns:
        Any: The value if found, None otherwise
    """
    # Ensure DataFrame has required columns
    required_columns = ["Isolate_Id", field_name]
    if not all(col in df.columns for col in required_columns):
        raise ValueError(f"DataFrame missing required column(s): {required_columns}")

    # Try to find matching row
    try:
        result = df[df["Isolate_Id"] == isolate_id][field_name].iloc[0]
        # Handle NaN values
        if pd.isna(result):
            return ""

        # Convert value to string
        return str(result.strip())
    except IndexError:
        return None


def read_header_list(txt):
    header_list = []
    with open(txt, "r") as txt_file:
        for line in txt_file:
            header_list.append(line.strip())
    return header_list


def rename_header(fasta, metadata, reverse_complementary_headers):
    renamed_fastas = []
    for record in SeqIO.parse(fasta, "fasta"):
        segment = get_segment_from_fasta_header(record.id)
        isolate_id = get_isolateid_from_fasta_header(record.id)
        isolate_name = get_field_value(metadata, isolate_id, "Isolate_Name")
        subtype = get_field_value(metadata, isolate_id, "Subtype")
        lineage = get_field_value(metadata, isolate_id, "Lineage")

        assert subtype[0] in ["A", "B"], "Unexpected subtype."
        if subtype[0] == "A":
            kraken = "kraken:taxid|11320"
        elif subtype[0] == "B":
            kraken = "kraken:taxid|11520"

        if record.id in reverse_complementary_headers:
            orientation = "rc"
        else:
            orientation = "f"

        # replace all spaces with _ to get proper fasta header for downstream processes
        renamed_header = f"{kraken}_{isolate_name}|{lineage}|{isolate_id}|{orientation}|{subtype}|{segment}".replace(
            " ", "_"
        ).replace(
            ",", "_"
        )
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
        get_metadata_from_excel(metadata),
        read_header_list(reverse_complementary_headers),
    )
