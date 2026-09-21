/*
Esqueleto del pipeline RNA-seq

1. FastQC: control de calidad de los FASTQ por run
        entrada: R1 y R2 originales (FASTQ)
        salida:  reportes de calidad (HTML y ZIP)
        - no modifica las lecturas

2. Trimming opcional: recorte de adaptaores y bases de baja calidad
        entrada: R1 y R2 originales (FASTQ)
        salida: R1 y R2 procesados (FASTQ) y reportes de recorte (formato por definir según la herramienta)
        - según revisión de calidad (paso 1)

3. FastQC posterior al trimming: control de caldiad de los FASTQ procesados
        entrada: R1 y R2 procesados (FASTQ)
        salida: reportes de calidad (HTML y ZIP)
        - se realizaría solo si se aplicó trimming

4. Agrupación de runs por muestra
        entrada: FASTQ de los runs correspondientes a una misma muestra
        salida: lecturas organizadas por muestra para Salmon
        - no mezclar R1 con R2
        - if no trimming -> usar lecturas originales

5. Salmon: cuantificación de transcritos por muestra
        entrada: lecturas por muestra (FASTQ) e índice de referencia
        salida: quant.sf y métricas de cuantificación
        - se obtendría una cuantificación por muestra biológica

6. MultiQC: integración de reportes de las herramientas
        entrada: reports de FastQC, recorte y métricas de Salmon
        salida: reporte integrado (HTML) y datos asociados
        - runir los reportes compatibles generados durante la ejecución
*/ 

proces fastqc {
    input:
    // identificadores de muestra y run, y archivos R1 y R2

    output:
    // reportes HTML y ZIP, asociados a sus identificadores

    script:
    """
    """
}
