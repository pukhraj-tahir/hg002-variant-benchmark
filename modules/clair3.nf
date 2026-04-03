process CLAIR3 {
    tag "Clair3"
    publishDir "${params.outdir}/clair3", mode: 'copy'

    input:
    path bam
    path bai
    path ref
    path ref_fai

    output:
    path "clair3_out/merge_output.vcf.gz",     emit: vcf
    path "clair3_out/merge_output.vcf.gz.tbi", emit: tbi

    script:
    """
    run_clair3.sh \
        --bam_fn=${bam} \
        --ref_fn=${ref} \
        --threads=${task.cpus} \
        --platform=hifi \
        --model_path=${params.clair3_model} \
        --output=clair3_out \
        --include_all_ctgs
    """
}
