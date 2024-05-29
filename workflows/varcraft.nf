/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowVarcraft.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { VARCRAFT_TOOL  } from '../modules/local/varcraft_tool'
include { MASH          } from '../modules/local/mash'
include { FASTP          } from '../modules/local/fastp'
include { BWA_MEM        } from '../modules/local/bwa_mem'
include { IVAR_CONSENSUS } from '../modules/local/ivar_consensus'
include { SUMMARY        } from '../modules/local/summary'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow VARCRAFT {

    ch_versions = Channel.empty()

    /*
    =============================================================================================================================
        LOAD SAMPLESHEET
    =============================================================================================================================
    */
    Channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map{ tuple(it.sample, file(it.assembly, checkIfExists: true), file(it.fastq_1, checkIfExists: true), file(it.fastq_2, checkIfExists: true)) }
        .set{ manifest }

    /*
    =============================================================================================================================
        PROCESS READS
    =============================================================================================================================
    */

    // MODULE: Run fastp
    FASTP (
        manifest.map{ sample, assembly, fastq_1, fastq_2 -> [ sample, fastq_1, fastq_2 ] }
    )
    ch_versions = ch_versions.mix(FASTP.out.versions.first())

    /*
    =============================================================================================================================
        CREATE ASSEMBLY VARIANTS
    =============================================================================================================================
    */

    // MODULE: Holly's tool
    VARCRAFT_TOOL (
        manifest.map{ sample, assembly, fastq_1, fastq_2 -> [ sample, assembly ] }
    )

    // Reformat channel - assumes the output file name is in the format sample.rep.ani.fa

    VARCRAFT_TOOL
        .out
        .variants.view()//flatten().collect()//.set{ variants_mash }
        //.flatten()
        //var_ch.view()

    
        //.map{ assembly -> [ file(assembly).getSimpleName(), assembly ] }
        //.combine(VARCRAFT_TOOL.out.variants.flatten(), by: 0)
        //.view().set{ mash_in }
        //.map(sample, variants -> [sample, variants]).view()
        //.set{mash_input}
      

    sam_as_ch = manifest.map{  sample, assembly, fastq_1, fastq_2 -> [ sample, assembly ] }
    
    //var_ch
    sam_as_ch.view()
    MASH (
        manifest.map{  sample, assembly, fastq_1, fastq_2 -> [ sample, assembly ] }, 
        //mash_in//.out.variants.set{ mash_in }
    )

    VARCRAFT_TOOL
        .out
        .variants
        .flatten()
        .map{ assembly -> [ file(assembly).getSimpleName(), assembly ] }
        .combine(FASTP.out.reads, by: 0)
        .set{ variants }

    /*
    =============================================================================================================================
        CREATE CONSENSUS
    =============================================================================================================================
    */

    // MODULE: Run BWA MEM
    BWA_MEM (
        variants
    )

    // MODULE: Run iVar
    IVAR_CONSENSUS (
        BWA_MEM.out.bam
    )


    /*
    =============================================================================================================================
        SUMMARIZE RESULTS
    =============================================================================================================================
    */

    // MODULE: Summary
    IVAR_CONSENSUS.out.consensus.collect().view()
    SUMMARY (
        IVAR_CONSENSUS.out.consensus.collect(),
        manifest.map{ sample, assembly, fastq_1, fastq_2 -> [ sample, assembly ] },
        MASH.out.mash_summary
    )


    /*

    // MODULE: 

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowVarcraft.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowVarcraft.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description, params)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()

    */
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
