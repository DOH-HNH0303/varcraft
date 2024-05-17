process MASH {
    label 'process_medium'

    container 'docker.io/staphb/mash:2.3'

    input:
    //path mash_in
    tuple val(sample), path(assembly), path(mash_in)//, stageAs: "ref/*")


    output:
    //path "${prefix}_mash_results.txt", emit: mash_summary
    path "mash_results.txt", emit: mash_summary

    when:
    task.ext.when == null || task.ext.when

    script:
    //def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${sample}"

    """
    echo "${mash_in} \n ${sample}"
    touch mash_results.txt
    """
    //# echo "${sample}"#\n\n${assembly}\n\n${mash_in}"

    // # mash sketch ${assembly} -s 10000 -o ${prefix}_reference
    // # mash sketch ${mash_in} -s 10000 -o ${prefix}_samples
    // # mash dist ${prefix}_reference.msh ${prefix}_samples.msh -p $task.cpus | \
    // # awk -v OFS='\t' '{print \$1, \$2, 100*(1-\$3)}' > ${prefix}_mash_results.txt
    // 
}