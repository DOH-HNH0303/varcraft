process SUMMARY {
    label 'process_medium'

    container 'docker.io/hnh0303/varcraft-tool:1.0'

    input:
    val sample
    path assemblies
    path summary

    output:
    path "${sample}_summary.csv", emit: summary

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    cat ${summary}
    ls ${assemblies} | wc -l > assembly_count.txt
    cat ${assemblies} > all.fa
    echo ${sample}
    summary.sh all.fa
    mv summary.csv ${sample}_summary.csv
    """
}
