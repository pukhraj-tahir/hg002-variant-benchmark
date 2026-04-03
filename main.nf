nextflow.enable.dsl = 2

include { CLAIR3                } from './modules/clair3'
include { DEEPVARIANT           } from './modules/deepvariant'
include { HAPPY as HAPPY_CLAIR3 } from './modules/happy'
include { HAPPY as HAPPY_DV    } from './modules/happy'

workflow {

    log.info """
    ================================================
     HG002 Variant Calling & Benchmarking Pipeline
     Nextflow DSL2 + SLURM + Singularity
    ================================================
     BAM      : ${params.bam}
     Ref      : ${params.ref}
     Truth VCF: ${params.truth_vcf}
     Output   : ${params.outdir}
    ================================================
    """.stripIndent()

    bam       = file(params.bam,                checkIfExists: true)
    bai       = file("${params.bam}.bai",       checkIfExists: true)
    ref       = file(params.ref,                checkIfExists: true)
    ref_fai   = file("${params.ref}.fai",       checkIfExists: true)
    truth_vcf = file(params.truth_vcf,          checkIfExists: true)
    truth_tbi = file("${params.truth_vcf}.tbi", checkIfExists: true)
    truth_bed = file(params.truth_bed,          checkIfExists: true)

    // Clair3 and DeepVariant run IN PARALLEL automatically
    CLAIR3(bam, bai, ref, ref_fai)
    DEEPVARIANT(bam, bai, ref, ref_fai)

    // Benchmark each caller against GIAB truth set
    HAPPY_CLAIR3("clair3",
          CLAIR3.out.vcf,      CLAIR3.out.tbi,
          truth_vcf, truth_tbi, truth_bed, ref, ref_fai)

    HAPPY_DV("deepvariant",
          DEEPVARIANT.out.vcf, DEEPVARIANT.out.tbi,
          truth_vcf, truth_tbi, truth_bed, ref, ref_fai)
}
