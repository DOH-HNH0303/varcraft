process SUMMARY {
    label 'process_medium'

    container 'docker.io/hnh0303/varcraft-tool:1.0'

    input:
    path assemblies

    output:
    path "summary.csv", emit: summary

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    cat ${assemblies} > all.fa
    summary.sh all.fa
    """
}
