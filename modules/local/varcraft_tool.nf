process VARCRAFT_TOOL {
    tag "${sample}"
    label 'process_medium'

    container 'docker.io/hnh0303/varcraft-tool:1.0'

    input:
    tuple val(sample), path(assembly)

    output:
    path "./output/*.fasta"

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    cpus=${params.max_cpus}
    threads=$((cpus*2))

    varcraft-tool.py \
    --input ./${assembly} \
    --max ${params.max_ani} \
    --min ${params.min_ani} \
    --step ${params.step} \
    --threads $threads \
    --outdir output

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        varcraft-tool: \$( varcraft-tool.py --version)
    END_VERSIONS
    """
}
