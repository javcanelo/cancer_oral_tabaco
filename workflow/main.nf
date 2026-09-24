nextflow.enable.dsl = 2

include { control_calidad } from './subworkflows/control_calidad'

workflow {
    runs = channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row ->
            tuple(
                row.sample, 
                row.run, 
                file(row.fastq_1, checkIfExists: true), 
                file(row.fastq_2, checkIfExists: true)
            )
        }

    control_calidad(runs)
}