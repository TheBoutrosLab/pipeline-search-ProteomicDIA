/** Merge one sample's fraction idXMLs into a single identification run. */
process merge_idXML_MSFragger {
    container params.docker_image_openms
    label 'process_medium'
    ext log_dir: { "${sample_name}/${task.process.replace(':', '/')}/task-${task.index}-attempt-${task.attempt}" }

    publishDir path: "${params.output_dir_base}/output/MSFragger",
        mode: 'copy',
        pattern: '*.idXML'

    input:
        tuple val(sample_name), path(idxml_files)

    output:
        tuple val(sample_name), path("${sample_name}_MSFragger.idXML"), emit: merged

    script:
        def output_name = "${sample_name}_MSFragger.idXML"
        def inputs = idxml_files instanceof Collection ? idxml_files : [idxml_files]
        def input_args = inputs.collect { "'" + it.toString().replace("'", "'\"'\"'") + "'" }.join(' ')
        if (inputs.size() == 1) {
            return """
            set -euo pipefail
            cp -L -- ${input_args} merged.idXML
            mv -- merged.idXML "${output_name}"
            """
        }
        """
        set -euo pipefail
        IDMerger \\
            -in ${input_args} \\
            -out merged.idXML \\
            -threads ${task.cpus} \\
            -merge_proteins_add_PSMs
        mv -- merged.idXML "${output_name}"
        """
}
