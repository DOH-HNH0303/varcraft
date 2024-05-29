process IVAR_CONSENSUS {
    tag "${prefix}"
    label 'process_high'

    conda "bioconda::ivar"
    container "staphb/ivar:1.4.2"

    input:
    tuple val(sample), path(ref), path(bam)

    output:
    path '*.fa',         emit: consensus
    path "versions.yml", emit: versions
    val "${sample}",     emit: sample

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = "${ref.baseName}"

    """
    # setup for pipe
    set -euxo pipefail

    # create mpilup and call consensus
    samtools mpileup -aa -A -Q 0 -d 0 ${bam} | \\
       ivar consensus \\
       -p ${prefix} \\
       ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools 2>&1 | grep "Version" | cut -f 2 -d ' ')
        ivar: \$(ivar version | head -n 1)
    END_VERSIONS
    """
}
