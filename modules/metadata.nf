process concat_metadata_excel_files {
    conda 'conda-forge::biopython=1.83 conda-forge::pandas=2.1.4 conda-forge::xlrd=2.0.1 conda-forge::openpyxl=3.1.2'
    label 'process_single'

    publishDir (
        path:    "${params.output}/intermediate",
        mode:    'copy',
        enabled: params.intermediate
    )

    input:
        path(metadata_excel)
        
    output:
        path("concatenated_metadata.xlsx")

    script:
    """
    concat_excels.py ${metadata_excel}
    """

    stub:
    """
    touch concatenated_metadata.xlsx
    """
}