/**
 * Search one unfractionated DIA mzML with the standalone MSFragger JAR.
 *
 * @input sample           tuple Sample name and DIA spectra in mzML format
 * @input decoy_database  path Target-decoy FASTA
 * @input fragger_params  path Generated native MSFragger parameters
 * @input executable      path Separately obtained MSFragger JAR
 * @output search_results tuple Sample name, one or more pepXML files, and PIN file
 */
process search_database_MSFragger {
    container params.docker_image_java
    label 'process_high'

    publishDir path: "${params.output_dir_base}/output/MSFragger",
        mode: 'copy',
        pattern: '*.{pepXML,pin}'

    input:
        tuple val(sample_name), path(mzml_file)
        path decoy_database, name: 'database.fasta'
        path fragger_params, name: 'fragger.params'
        path executable, name: 'MSFragger.jar'

    output:
        tuple val(sample_name), path("${mzml_file.baseName}*.pepXML"), path("${mzml_file.baseName}.pin"), emit: search_results

    script:
        def heap_mb = Math.max(256, (task.memory.toMega() * 0.8) as int)
        """
        set -euo pipefail
        java -Xmx${heap_mb}m -XX:ActiveProcessorCount=${task.cpus} \\
            -jar MSFragger.jar fragger.params "${mzml_file}"
        """
}
