process BWA_MEM {
    tag "${prefix}"
    label 'process_high'

    conda "bioconda::bwa"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:219b6c272b25e7e642ae3ff0bf0c5c81a5135ab4-0' :
        'biocontainers/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:219b6c272b25e7e642ae3ff0bf0c5c81a5135ab4-0' }"

    input:
    tuple val(sample), path(ref), path(fastq_1), path(fastq_2)

    output:
    tuple val(sample), path(ref), path('*.bam'), emit: bam
    tuple val(sample), path('*.coverage.txt'),   emit: coverage
    tuple val(sample), path('*.stats.txt'),      emit: stats
    path "versions.yml",                         emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = "${ref.baseName}"

    """
    # setup for pipe
    set -euxo pipefail

    # index the reference
    bwa index ${ref}

    # run bwa mem, select only mapped reads, convert to .bam, and sort
    bwa mem -t ${task.cpus} ${ref} ${fastq_1} ${fastq_2} | samtools view -b -F 4 - | samtools sort - > ${prefix}.bam

    # gather read stats
    samtools coverage ${prefix}.bam > ${prefix}.coverage.txt
    samtools stats --threads ${task.cpus} ${prefix}.bam > ${prefix}.stats.txt
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa-mem: \$(bwa 2>&1 | grep "Version" | cut -f 2 -d ' ')
    END_VERSIONS
    """
}
