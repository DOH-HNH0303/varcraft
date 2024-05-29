process MASH {
    label 'process_medium'

    tag "${prefix}"

    container 'docker.io/staphb/mash:2.3'

    input:
    tuple val(sample) , path(mash_in), path(assembly)
    //tuple val(sample), path(assembly)//, path(mash_in)
    //path(mash_in)//, stageAs: "ref/*")
    //tuple val(sample), path(assembly)


    output:
    path "${prefix}_mash_results.txt", emit: mash_summary
    tuple val(sample), path("${prefix}_mash_results.txt"), emit: mash_out

    when:
    task.ext.when == null || task.ext.when

    script:
    //def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${sample}"

    """
    ls

    mash sketch ${assembly} -s 10000 -o ${prefix}_reference
    mash sketch ${mash_in} -s 10000 -o ${prefix}_samples 
    mash dist ${prefix}_reference.msh ${prefix}_samples.msh -p $task.cpus | \
    awk -v OFS='\t' '{print \$1, \$2, 100*(1-\$3)}' > ${prefix}_mash_results.txt
    """
}

//mash sketch ${mash_in} -s 10000 -o ${prefix}_samples