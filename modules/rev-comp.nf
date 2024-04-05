process align_reference{
    tag "$segment"
    conda 'bioconda::mafft=7.520'
    label 'process_high'

    input:
        tuple val(segment), path(reference)
        
    output:
        tuple val(segment), path("${segment}_reference_mafft.fasta")

    script:
    """
    # align only the reference without the adjust direction option - make sure the references are not reverse complementatry aligned
    mafft --thread ${task.cpus} ${reference} > ${segment}_reference_mafft.fasta
    """
}

process add_align_segments{
    tag "$segment"
    conda 'bioconda::mafft=7.520'
    label 'process_high'

    publishDir (
        path: "${params.output}/intermediate",
        mode: 'copy',
        enabled: params.intermediate,
        pattern: "${segment}_rc_headers.txt"
    )

    input:
        tuple val(segment), path(reference_aligment), path(fasta)
        
    output:
        tuple val(segment), path("${segment}_rc_headers.txt"), path(fasta, includeInputs: true)

    script:
    """
    # https://mafft.cbrc.jp/alignment/software/closelyrelatedviralgenomes.html
    # add the segment fastas to the aligment - potentially as reverse complemet
    # keeplength - no gaps are inserted to the reference sequence, ie, corresponding sites in the other sequences are deleted.
    mafft --thread ${task.cpus} --adjustdirection --keeplength --addfragments ${fasta} ${reference_aligment} > ${segment}_mafft.fasta

    grep '^>_R_' ${segment}_mafft.fasta | sed "s/>_R_//" > ${segment}_rc_headers.txt
    """
}

process correct_reverse_complements {
    tag "$segment"
    conda 'bioconda::seqkit=2.6.1'
    label 'process_low'

    input:
        tuple val(segment), path(reverse_complement_list), path(fasta)
        
    output:
        tuple val(segment), path(reverse_complement_list), path("${segment}_rc-fixed.fasta")

    script:
    """
    seqkit grep -v -f ${reverse_complement_list} ${fasta} > ${segment}_rc-fixed.fasta
    seqkit grep -f ${reverse_complement_list} ${fasta} | seqkit seq -r -p -v >> ${segment}_rc-fixed.fasta
    """
}