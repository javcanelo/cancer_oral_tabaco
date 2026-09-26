process salmon_quant {
    tag "${sample}"
    cpus 2
    maxForks 1

    publishDir "${params.output_dir}/salmon", mode: 'copy'

    input:
    tuple val(sample), path(reads_1), path(reads_2)
    path salmon_index

    output:
    tuple val(sample), path("${sample}"), emit: quantifications

    script:
    def r1_args = [reads_1].flatten()
        .collect { "\"${it}\"" }
        .join(' ')

    def r2_args = [reads_2].flatten()
        .collect { "\"${it}\"" }
        .join(' ')

    
    """
    salmon quant \
        --index "${salmon_index}" \
        --libType A \
        --mates1 ${r1_args} \
        --mates2 ${r2_args} \
        --validateMappings \
        --seqBias \
        --gcBias \
        --threads ${task.cpus} \
        --output "${sample}"


    test -s "${sample}/quant.sf"
    test -s "${sample}/aux_info/meta_info.json"
    """    
}
