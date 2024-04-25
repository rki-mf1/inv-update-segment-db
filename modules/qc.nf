process filter_fasta {
    conda 'conda-forge::r-base=4.3.2 conda-forge::r-data.table=1.14 conda-forge::r-seqinr=4.2_30'
    label 'process_single'

    input:
        tuple path(fasta), path(stats)
        
    output:
        path("${fasta.baseName}_fewAmbig-corLen.fasta")

    script:
    """
    clean_segment_DB.R ${fasta.baseName} ${fasta} ${stats}
    """
    
    stub:
    """
    touch ${fasta.baseName}_fewAmbig-corLen.fasta
    """
}

process get_stats {
    conda 'bioconda::seqkit=2.6.1'
    label 'process_low'

    publishDir (
        path: "${params.output}/intermediate",
        mode: 'copy',
        enabled: params.intermediate,
        pattern: "${fasta.baseName}_fx2tab.tsv"
    )

    input:
        path(fasta)
        
    output:
        tuple path(fasta), path("${fasta.baseName}_fx2tab.tsv")

    script:
    """
    seqkit fx2tab -n -B efijlopqzx -n -B WSKMYRVHDBN -C WSKMYRVHDBN -l ${fasta} > ${fasta.baseName}_fx2tab.tsv
    """
    
    stub:
    """
    touch ${fasta.baseName}_fx2tab.tsv
    """
}

process remove_duplicates {
    conda 'bioconda::seqkit=2.6.1'
    label 'process_low'

    input:
        path(fasta)
        
    output:
        path("${fasta.baseName}_noDups.fasta")

    script:
    """
    #remove seq with identical headers and identical sequences
    seqkit rmdup -n ${fasta} | seqkit rmdup -s > ${fasta.baseName}_noDups.fasta
    """

    stub:
    """
    touch ${fasta.baseName}_noDups.fasta
    """
}