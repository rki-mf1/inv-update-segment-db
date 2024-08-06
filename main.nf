nextflow.enable.dsl=2

// terminal prints
if (params.help) { exit 0, helpMSG() }

//include modules
include { concat_metadata_excel_files                                        } from "./modules/metadata"
include { rename_headers; split_by_segment; concat_fasta                     } from "./modules/utils"
include { filter_fasta; get_stats; remove_duplicates                         } from "./modules/qc"
include { align_reference; add_align_segments; correct_reverse_complements;  } from "./modules/rev-comp"


workflow {
    // collect metadata
    Channel.fromPath(params.input_metadata, checkIfExists: true)
        | collect
        | concat_metadata_excel_files
        | set { metadata }

    // collect all segemnts and filter them
    Channel.fromPath(params.input_segments, checkIfExists: true)
        | collect
        | concat_fasta
        | remove_duplicates
        | split_by_segment
        | flatten
        | get_stats
        | filter_fasta
        | map { it -> tuple(it.simpleName.split('_')[0], it) }
        | set { segments }
    
    // find and fix reverse complementary segemnts
    Channel.fromPath(params.references, checkIfExists: true)
        | map { it -> tuple(it.simpleName.split('_')[0], it) }
        | align_reference
        | join ( segments )
        | add_align_segments
        | correct_reverse_complements
        | set { aligments }

    // rename headers
    rename_headers(aligments, metadata)
}

def helpMSG() {
    c_green = "\033[0;32m";
    c_reset = "\033[0m";
    c_yellow = "\033[0;33m";
    c_blue = "\033[0;34m";
    c_dim = "\033[2m";
    log.info """
    ____________________________________________________________________________________________

    ${c_yellow}Usage example:${c_reset}
    nextflow run rki-mf1/inv-update-segment-db \\
        --input_segments '/path/to/fastas/*.fasta' \\
        --input_metadata '/path/to/metadata_tables/*.xls' \\
        --references '/path/to/segment/references/*.fasta' 

    ${c_yellow}Required parameters:${c_reset}
    ${c_green}--input_segments${c_reset} (Multi) FASTA file(s) 
            ${c_dim}Assumed header: 8 fields separated by `|` , `segment` required in the second and `isolate_id` in the fourth field:
            >number|segment|isolate_name|isolate_id|empty|subtype${c_dim}
    ${c_green}--input_metadata${c_reset} Excel table(s) containing metadata for --input_segments
            ${c_dim}Required fields: `Isolate_Id`, `Isolate_Name`, `Subtype`, `Lineage`
            `Isolate_Id` in the table needs to match `isolate_id` in the input_segments fasta header ${c_dim}
    ${c_green}--references${c_reset}     8 (multi) FASTA files containing reference sequences for each segment. The references are used
            to check if the input_segments are reverse complementary compared to the references.
            ${c_dim}Required prefix: `segment_`, where segment is one of [HA, MP, NA, NP, NS, PA, PB1, PB2]
            e.g. HA_reference.fasta${c_dim}

    ${c_yellow}Optional parameters:${c_reset}
    --output            The output directory where the results will be saved [default: $params.output]
    --intermediate      Publish also intermediate results [default: $params.intermediate]

    ${c_yellow}Computing options:${c_reset}
    --max_cpus       Maximum number of CPUs that can be requested for any single job [default: $params.max_cpus]
    --max_memory     Maximum amount of memory that can be requested for any single job [default: $params.max_memory]
    --max_time       Maximum amount of time that can be requested for any single job [default: $params.max_time]

    ${c_dim}For Nextflow options, see https://www.nextflow.io/docs/latest/cli.html#options and https://www.nextflow.io/docs/latest/cli.html#run${c_reset}

    ${c_yellow}Execution/Engine profiles:${c_reset}
    The pipeline supports profiles to run via different ${c_green}Executers${c_reset} and ${c_blue}Engines${c_reset} e.g.: -profile ${c_green}local${c_reset},${c_blue}mamba${c_reset}
    
    ${c_green}Executer${c_reset} (choose one):
      local
      slurm
    
    ${c_blue}Engines${c_reset} (choose one):
      conda
      mamba
    
    Per default: -profile slurm,mamba is executed. 
    """.stripIndent()
}