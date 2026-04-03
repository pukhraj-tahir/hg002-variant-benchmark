process DEEPVARIANT {
    tag "DeepVariant"
    publishDir "${params.outdir}/deepvariant", mode: 'copy'

    input:
    path bam
    path bai
    path ref
    path ref_fai

    output:
    path "hg002_dv.vcf.gz",     emit: vcf
    path "hg002_dv.vcf.gz.tbi", emit: tbi

    script:
    """
    run_deepvariant \
        --model_type=PACBIO \
        --ref=${ref} \
        --reads=${bam} \
        --output_vcf=hg002_dv.vcf.gz \
        --output_gvcf=hg002_dv.g.vcf.gz \
        --num_shards=${task.cpus}
    """
}
