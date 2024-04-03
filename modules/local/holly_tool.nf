process HOLLY_TOOL {
    tag "${sample}"
    label 'process_medium'

    container 'docker.io/DOH-HNH0303/holly_tool:1.0'

    input:
    tuple val(sample), path(assembly)

    output:
    path "*.fa"

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    holly_tool.py --input ${assembly} --max ${params.max_ani} --min ${params.min_ani} --step ${params.step}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        holly_tool: \$( holly_tool.py --version)
    END_VERSIONS
    """
}
