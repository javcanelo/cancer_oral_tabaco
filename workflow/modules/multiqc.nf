process multiqc {
    tag "reporte_integrado"
    cpus 1

    publishDir "${params.output_dir}/multiqc", mode: 'copy'

    input:
    path report_files, stageAs: 'inputs/*'

    output:
    path "multiqc_report.html", emit: report
    path "multiqc_report_data", emit: data

    script:
    """
    multiqc inputs \
        --outdir . \
        --filename multiqc_report.html \
        --fullnames
    """
}