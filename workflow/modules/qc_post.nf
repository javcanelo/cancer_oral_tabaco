process fastqc_post_trimming {
    tag "${sample}:${run}"
    cpus 2

    publishDir "${params.output_dir}/fastqc_trimmed", mode:'copy'

    input:
    tuple val(sample), val(run), path(fastq_1), path(fastq_2)

    output:
    tuple val(sample), val(run),
        path("*_fastqc.html"),
        path("*_fastqc.zip"),
        emit: reports

    script:
    """
    fastqc \
        --threads ${task.cpus} \
        --outdir . \
        "${fastq_1}" "${fastq_2}"
    """
}