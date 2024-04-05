nextflow.enable.dsl=2

//include modules
include { concat_metadata_excel_files } from "./modules/metadata"
include { rename_headers; split_by_segment; concat_fasta } from "./modules/utils"
include { filter_fasta; get_stats; remove_duplicates } from "./modules/qc"
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