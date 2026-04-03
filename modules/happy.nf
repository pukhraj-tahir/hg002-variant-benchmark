process HAPPY {
    tag "hap.py - ${caller}"
    publishDir "${params.outdir}/benchmark/${caller}", mode: 'copy'

    input:
    val  caller
    path query_vcf
    path query_tbi
    path truth_vcf
    path truth_tbi
    path truth_bed
    path ref
    path ref_fai

    output:
    path "${caller}.summary.csv",  emit: summary
    path "${caller}.extended.csv", emit: extended
    path "${caller}.*"

    script:
    """
    hap.py \
        ${truth_vcf} ${query_vcf} \
        -f ${truth_bed} \
        -r ${ref} \
        -o ${caller} \
        --engine=vcfeval \
        --threads=${task.cpus}
    """
}
