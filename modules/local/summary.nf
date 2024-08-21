process SUMMARY {
    label 'process_medium'

    container 'docker.io/jdj0303/epitome-base:1.0'

    input:
    path assemblies
    path mash

    output:
    path "df_fitted.csv", emit: df_fitted
    path "threshold.txt", emit: threshold
    path "*.jpg",         emit: plots

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    summary.sh ${assemblies}
    summary.R
    """
}
