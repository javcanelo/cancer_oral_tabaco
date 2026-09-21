workflow {
    runs = channel.fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row ->
            tuple(row.sample, row.run, row.fastq_1, row.fastq_2)
        }

    runs.view()
}