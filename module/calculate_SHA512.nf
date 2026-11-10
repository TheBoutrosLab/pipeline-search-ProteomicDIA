/** Write a SHA-512 sidecar for one published MSFragger result file. */
process calculate_SHA512 {
    container params.docker_image_java
    label 'process_low'
    ext log_dir: { "${sample_name}/${task.process.replace(':', '/')}/task-${task.index}-attempt-${task.attempt}" }

    publishDir path: { "${params.output_dir_base}/output/MSFragger${result_group == 'fraction' ? '/per_fraction' : ''}" },
        mode: 'copy',
        pattern: '*.sha512'

    input:
        tuple val(sample_name), val(result_group), path(result_file)

    output:
        path "${result_file.name}.sha512", emit: checksum

    script:
        """
        set -euo pipefail
        sha512sum -- "${result_file}" > "${result_file.name}.sha512"
        """
}
