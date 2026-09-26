nextflow.enable.dsl = 2

include { control_calidad } from './subworkflows/control_calidad'
include { salmon_quant } from './modules/salmon'
include { multiqc } from './modules/multiqc'

workflow {
    runs = channel
        .fromPath(params.samplesheet, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            tuple(
                row.sample, 
                row.run, 
                file(row.fastq_1, checkIfExists: true), 
                file(row.fastq_2, checkIfExists: true)
            )
        }

    index_ch = channel.value(
        file(params.salmon_index, checkIfExists: true)
    )

    control_calidad(runs)

    // mantener cada run unido a sus 2 mates
    reads_by_sample = control_calidad.out.trimmed_reads
        .map { sample, run, r1, r2 ->
            tuple(sample, tuple(run, r1, r2))
        }
        .groupTuple()
        .map { sample, records ->
            def ordered = records.sort { a, b -> a[0] <=> b[0] }
            
            tuple(
                sample,
                ordered.collect { it[1] },
                ordered.collect { it[2] }
            )
        }

    salmon_quant(reads_by_sample, index_ch)

    raw_qc_files = control_calidad.out.raw_reports
        .map { sample, run, html, zip -> zip }
    
    trimmed_qc_files = control_calidad.out.trimmed_reports
        .map { sample, run, html, zip -> zip }

    fastp_files = control_calidad.out.trimmed_reports
        .map { sample, run, html, json -> json }

    salmon_files = salmon_quant.out.quantifications
        .map { sample, quant_dir -> quant_dir }
    
    all_reports = raw_qc_files
        .mix(trimmed_qc_files, fastp_files, salmon_files)
        .flatten()
        .unique { it.toString() }
        .collect()

    multiqc(all_reports)

}