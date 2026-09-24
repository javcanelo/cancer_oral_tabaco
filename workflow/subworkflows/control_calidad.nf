include { fastqc } from '../modules/qc'

workflow control_calidad {
    take:
    runs

    main:
    fastqc(runs)
    
    emit:
    raw_reports = fastqc.out.reports
}