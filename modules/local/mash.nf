process MASH {
    label 'process_medium'

    container 'docker.io/hnh0303/varcraft-tool:1.0'

    input:
    path mash_in

    output:
    path "all.txt", emit: summary

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    cat ${mash_in} > all.txt
    """
}