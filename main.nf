params.base = "/hdd4/sines/specialtopicsinbioinformatics/pukhraj.sines/hg002_variant_pipeline"

process HAPPY_CLAIR3 {
    tag "Benchmark Clair3"
    input:
        val vcf
        val ref
    script:
    """
    mkdir -p ${params.base}/benchmark/clair3_results
    singularity exec \
        --bind ${params.base} \
        ${params.base}/containers/hap.py_latest.sif \
        /opt/hap.py/bin/hap.py \
        ${params.base}/benchmark/truth/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz \
        ${vcf} \
        -f ${params.base}/benchmark/truth/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed \
        -r ${ref} \
        -o ${params.base}/benchmark/clair3_results/clair3 \
        --threads 8
    """
}

process HAPPY_DEEPVARIANT {
    tag "Benchmark DeepVariant"
    input:
        val vcf
        val ref
    script:
    """
    mkdir -p ${params.base}/benchmark/deepvariant_results
    singularity exec \
        --bind ${params.base} \
        ${params.base}/containers/hap.py_latest.sif \
        /opt/hap.py/bin/hap.py \
        ${params.base}/benchmark/truth/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz \
        ${vcf} \
        -f ${params.base}/benchmark/truth/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed \
        -r ${ref} \
        -o ${params.base}/benchmark/deepvariant_results/deepvariant \
        --threads 8
    """
}

workflow {
    ref             = "${params.base}/data/GRCh38.primary_assembly.genome.fa"
    clair3_vcf      = "${params.base}/results/clair3/merge_output.vcf.gz"
    deepvariant_vcf = "${params.base}/results/deepvariant.vcf.gz"
    HAPPY_CLAIR3(clair3_vcf, ref)
    HAPPY_DEEPVARIANT(deepvariant_vcf, ref)
}
