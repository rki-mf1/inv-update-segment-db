# inv-update-segment-db

Update pipeline for the reference segment DB for FluPipe (https://github.com/rki-mf1/FluPipe)

## Quick installation

The pipeline is written in [`Nextflow`](https://nf-co.re/usage/installation), which can be used on any POSIX compatible system (Linux, OS X, etc). Windows system is supported through [WSL](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux). You need `Nextflow` installed and `conda` to run the steps of the pipeline:

1. Install `Nextflow`
   <details><summary>click here for a bash one-liner </summary>

   ```bash
   wget -qO- https://get.nextflow.io | bash
   # In the case you don’t have wget
   # curl -s https://get.nextflow.io | bash
   ```

   </details>

1. Install [`conda`](https://conda.io/miniconda.html)
   <details><summary>click here for a bash two-liner for Miniconda3 Linux 64-bit</summary>

   ```bash
   wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
   bash Miniconda3-latest-Linux-x86_64.sh
   ```

   </details>

OR

1. Install `conda`
   <details><summary>click here for a bash two-liner for Miniconda3 Linux 64-bit</summary>

   ```bash
   wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
   bash Miniconda3-latest-Linux-x86_64.sh
   ```

   </details>

1. Install `Nextflow` via `conda`
   <details><summary>click here to see how to do that</summary>

   ```bash
   conda create -n nextflow -c bioconda nextflow
   conda active nextflow
   ```

All other dependencies and tools will be installed within the pipeline via `conda`.

## Example run

```bash
# conda active nextflow
nextflow run rki-mf1/inv-update-segment-db \
    -profile local,mamba \
    --input_segments '/path/to/fastas/*.fasta' \
    --input_metadata '/path/to/metadata_tables/*.xls' \
    --references '/path/to/segment/references/*.fasta' \
    --intermediate
```

## Peculiarities and requirements

The assumptions about input FASTA header and input metadata are quite tailored to GISAID/Epiflu data.

### --input_segments

Assumed header: variable number of fields separated by `|`, where 

- one field has to be one of ["HA", "MP", "NA", "NP", "NS", "PA", "PB1", "PB2"], and,
- one field has to match an isolate ID: `^EPI_ISL_\d+$`

### --input_metadata

- Required fields: `Isolate_Id`, `Isolate_Name`, `Subtype`, `Lineage`
- `Isolate_Id` in the table needs to match the isolate ID in the `--input_segments` FASTA header (see above)

### --references

- Required prefix: `segment_`, where segment is one of ["HA", "MP", "NA", "NP", "NS", "PA", "PB1", "PB2"]
  - e.g. `HA_reference.fasta`

### Output segment FASTA header format

The output FASTA headers are renamed in the following pattern:

```
>{kraken}_{isolate_name}|{lineage}|{isolate_id}|{direction}|{subtype}|{segment}
```

where `kraken` is `kraken:taxid|11320` in case of Influenza A and `kraken:taxid|11520` in case of Influenza B; and `direction` is `rc` (reverse complementary) or `f` (forward) compared to the respective reference (`--references`).

## Workflow

1. `input_metadata` files are concatenated
2. `input_segments` are
   1. concatenated,
   2. name duplicates are removed,
   3. split into 8 FASTA files, one for each segment (based on FASTA header), and
   4. filter FASTA based on `seqkit fx2tab` stats.
3. Each reference file corresponding to one segment is
   1. aligned with `MAFFT`, and
   2. filtered segments from step 2.4 are added to the `MAFFT` alignment.
      1. Reverse complementary segments are reverse complemented.
      2. Filtered and reverse complemented segments are renamed.

## Help message

<details><summary>click here to see the complete help message</summary>

```
Usage example:
nextflow run rki-mf1/inv-update-segment-db \
    --input_segments '/path/to/fastas/*.fasta' \
    --input_metadata '/path/to/metadata_tables/*.xls' \
    --references '/path/to/segment/references/*.fasta'

Required parameters:
--input_segments (Multi) FASTA file(s)
        Assumed header: fields separated by `|`, where 
                - one field has to be one of ["HA", "MP", "NA", "NP", "NS", "PA", "PB1", "PB2"], 
                AND
                - one field has to match an isolate ID: `^EPI_ISL_\d+$`
--input_metadata Excel table(s) containing metadata for --input_segments
        Required fields: `Isolate_Id`, `Isolate_Name`, `Subtype`, `Lineage`
        `Isolate_Id` in the table needs to match `isolate_id` in the input_segments fasta header
--references     8 (multi) FASTA files containing reference sequences for each segment. The references are used
        to check if the input_segments are reverse complementary compared to the references.
        Required prefix: `segment_`, where segment is one of [HA, MP, NA, NP, NS, PA, PB1, PB2]
        e.g. HA_reference.fasta

Optional parameters:
--output            The output directory where the results will be saved [default: results]
--intermediate      Publish also intermediate results [default: false]

Computing options:
--max_cpus       Maximum number of CPUs that can be requested for any single job [default: 20]
--max_memory     Maximum amount of memory that can be requested for any single job [default: 128.GB]
--max_time       Maximum amount of time that can be requested for any single job [default: 16.h]

For Nextflow options, see https://www.nextflow.io/docs/latest/cli.html#options and https://www.nextflow.io/docs/latest/cli.html#run

Execution/Engine profiles:
The pipeline supports profiles to run via different Executers and Engines e.g.: -profile local,mamba

Executer (choose one):
  local
  slurm

Engines (choose one):
  conda
  mamba

Per default: -profile slurm,mamba is executed.
```

</details>

## Citations

A list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
