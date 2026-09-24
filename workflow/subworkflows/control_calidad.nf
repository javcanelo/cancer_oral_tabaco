include { fastqc } from '../modules/qc'
include { fastp } from '../modules/trimming'
include { fastqc_post_trimming } from '../modules/qc_post'

workflow control_calidad {
    take:
    runs

    main:
    fastqc(runs)
    fastp(runs)
    fastqc_post_trimming(fastp.out.reads)
    
    emit:
    raw_reports = fastqc.out.reports
    trimmed_reads = fastp.out.reads 
    trimming_reports = fastp.out.reports
    trimmed_reports = fastqc_post_trimming.out.reports
}
