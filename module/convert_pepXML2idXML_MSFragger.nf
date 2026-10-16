/** Combine all MSFragger DIA pepXML ranks for one sample into one idXML. */
process convert_pepXML2idXML_MSFragger {
    container params.docker_image_pyopenms
    label 'process_medium'
    ext containerOptions: {
        params.container_mount_flag
            ? "${params.container_mount_flag} \"${projectDir}/src:${projectDir}/src:ro\""
            : ''
    }

    publishDir path: "${params.output_dir_base}/output/MSFragger",
        mode: 'copy',
        pattern: '*.idXML'

    input:
        tuple val(sample_name), path(pepxml_files), path(mzml_file)

    output:
        tuple val(sample_name), path("${sample_name}_MSFragger.idXML"), emit: idxml

    script:
        """
        set -euo pipefail
        python "${projectDir}/src/PepXMLs2IdXML.py" \\
            --mzml "${mzml_file}" \\
            --input-dir . \\
            --output "${sample_name}_MSFragger.idXML"
        """
}
