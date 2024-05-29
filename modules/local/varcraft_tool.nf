process VARCRAFT_TOOL {
    tag "${sample}"
    label 'process_medium'

    container 'docker.io/hnh0303/varcraft-tool:1.0'

    input:
    tuple val(sample), path(assembly, stageAs: "ref/*")

    output:
    path "output/*.fasta", emit: variants
    tuple val(sample), "output/*.fasta", emit: var_tuple

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    varcraft-tool.py \\
        --input ref/ \\
        --max ${params.max_ani} \\
        --min ${params.min_ani} \\
        --step ${params.step} \\
        --threads ${params.max_cpus} \\
        --rep ${params.rep} \\
        --outdir output

    #cat <<-END_VERSIONS > versions.yml
    #"${task.process}":
    #    varcraft-tool: \$(varcraft-tool.py --version)
    #END_VERSIONS
    """
}
