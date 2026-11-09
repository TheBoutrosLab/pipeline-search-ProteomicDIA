/** Combine MSFragger DIA pepXML ranks for one fraction into one idXML. */
process convert_pepXML2idXML_MSFragger {
    container params.docker_image_pyopenms
    label 'process_medium'
    ext log_dir: { "${sample_name}/${fraction}/${task.process.replace(':', '/')}/task-${task.index}-attempt-${task.attempt}" }
    ext containerOptions: {
        params.container_mount_flag
            ? "${params.container_mount_flag} \"${projectDir}/src:${projectDir}/src:ro\""
            : ''
    }

    publishDir path: "${params.output_dir_base}/output/MSFragger/per_fraction",
        mode: 'copy',
        pattern: '*.idXML'

    input:
        tuple val(sample_name), val(fraction), path(pepxml_files), path(mzml_file)

    output:
        tuple val(sample_name), val(fraction), path("${mzml_file.baseName}_MSFragger.idXML"), emit: idxml

    script:
        """
        set -euo pipefail
        python "${projectDir}/src/PepXMLs2IdXML.py" \\
            --mzml "${mzml_file}" \\
            --fraction "${fraction}" \\
            --input-dir . \\
            --output "${mzml_file.baseName}_MSFragger.idXML"
        """
}
