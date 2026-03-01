singularity exec containers/hap.py_latest.sif \
/opt/hap.py/bin/hap.py \
benchmark/truth/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz \
results/clair3/merge_output.vcf.gz \
-f benchmark/truth/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed \
-r data/GRCh38.primary_assembly.genome.fa \
-o benchmark/clair3_results/clair3 \
--threads 16
