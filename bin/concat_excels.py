#!/usr/bin/env python

import sys
import pandas as pd


def concatenate_excel_files(output_filename, *input_files):
    # Initialize an empty DataFrame to store the concatenated data
    concatenated_data = pd.DataFrame()

    # Iterate through the input Excel files
    for file in input_files:
        # Read each Excel file into a DataFrame
        data = pd.read_excel(file)

        # Concatenate the data to the existing DataFrame
        concatenated_data = pd.concat([concatenated_data, data], ignore_index=True)

    # Write the concatenated data to a new Excel file
    concatenated_data.to_excel(output_filename, index=False)


if __name__ == "__main__":
    output_file = "concatenated_metadata.xlsx"
    input_files = sys.argv[1:]

    concatenate_excel_files(output_file, *input_files)
