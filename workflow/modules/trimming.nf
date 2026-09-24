process fastp { 
    tag "${sample}:${run}"
    cpus 2

    publishDir "${params.output_dir}/fastp", mode:'copy'

    input:
    tuple val(sample), val(run), path(fastq_1), path(fastq_2)

    output:
        tuple val(sample), val(run),
            path("${run}_1.trimmed.fastq.gz"),
            path("${run}_2.trimmed.fastq.gz"),
            emit: reads

        tuple val(sample), val(run),
            path("${run}_fastp.html"),
            path("${run}_fastp.json"),
            emit: reports
            
    script:
    """
    fastp \
        --in1 "${fastq_1}" \
        --in2 "${fastq_2}" \
        --out1 "${run}_1.trimmed.fastq.gz" \
        --out2 "${run}_2.trimmed.fastq.gz" \
        --detect_adapter_for_pe \
        --trim_poly_g \
        --length_required 30 \
        --thread ${task.cpus} \
        --html "${run}_fastp.html" \
        --json "${run}_fastp.json"
    """
}