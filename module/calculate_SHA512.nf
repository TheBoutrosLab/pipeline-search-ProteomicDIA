/** Write a SHA-512 sidecar for one published MSFragger result file. */
process calculate_SHA512 {
    container params.docker_image_java
    label 'process_low'

    publishDir path: "${params.output_dir_base}/output/MSFragger",
        mode: 'copy',
        pattern: '*.sha512'

    input:
        path result_file

    output:
        path "${result_file.name}.sha512", emit: checksum

    script:
        """
        set -euo pipefail
        sha512sum -- "${result_file}" > "${result_file.name}.sha512"
        """
}
