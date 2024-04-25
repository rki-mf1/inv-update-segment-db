process rename_headers {
    tag "$segment"
    conda 'conda-forge::biopython=1.83 conda-forge::pandas=2.1.4 conda-forge::xlrd=2.0.1 conda-forge::openpyxl=3.1.2'
    label 'process_single'

    publishDir (
        path: "${params.output}",
        mode: 'copy',
        pattern: "*.fasta",
        saveAs: { fa -> "${segment}.all_noIdent_fewAmbig_corLen.fasta" }
    )

    input:
        tuple val(segment), path(reverse_complement_list), path(fasta)
        path(metadata_excel)
        
    output:
        tuple val(segment), path("*.fasta")

    script:
    """
    rename_header.py ${fasta} ${metadata_excel} ${segment}_rc_headers.txt
    """

    stub:
    """
    touch HA_renamed.fasta MP_renamed.fasta NA_renamed.fasta NP_renamed.fasta NS_renamed.fasta PA_renamed.fasta PA_renamed.fasta PB1_renamed.fasta PB2_renamed.fasta
    """
}

process split_by_segment {
    conda 'conda-forge::biopython=1.83 conda-forge::pandas=2.1.4 conda-forge::xlrd=2.0.1 conda-forge::openpyxl=3.1.2'
    label 'process_single'

    input:
        path(fasta)
        
    output:
        path("*.fasta")

    script:
    """
    split_by_segment.py ${fasta}
    """

    stub:
    """
    touch HA.fasta MP.fasta NA.fasta NP.fasta NS.fasta PA.fasta PA.fasta PB1.fasta PB2.fasta
    """
}

process concat_fasta { 
    label 'process_single'

    input:
        path(fasta)
        
    output:
        path("all_records.fasta")

    script:
    """
    cat ${fasta} > all_records.fasta
    dos2unix *.fasta 
    """
    stub:
    """
    touch all_records.fasta
    """
}