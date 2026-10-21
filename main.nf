#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { write_MSFraggerParams } from './module/write_MSFraggerParams.nf'
include { search_database_MSFragger } from './module/search_database_MSFragger.nf'
include { convert_pepXML2idXML_MSFragger } from './module/convert_pepXML2idXML_MSFragger.nf'
include { calculate_SHA512 } from './module/calculate_SHA512.nf'

/** Read one unfractionated mzML per sample from the input CSV. */
def readInputMzML(String input_csv) {
    def csv = file(input_csv)

    return Channel.fromPath(csv)
        .splitCsv(header: true)
        .toList()
        .map { rows ->
            if (!rows) {
                throw new IllegalArgumentException("Input CSV has no samples: ${csv}")
            }

            def sample_names = [] as Set
            def input_paths = [] as Set
            def mzml_basenames = [] as Set
            rows.collect { row ->
                if (row.keySet() != (['sample_name', 'mzML'] as Set)) {
                    throw new IllegalArgumentException('Input CSV must have exactly sample_name,mzML columns')
                }

                def sample_name = row.sample_name?.trim()
                if (!(sample_name ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/)) {
                    throw new IllegalArgumentException("Invalid sample_name: ${row.sample_name}")
                }
                if (!sample_names.add(sample_name)) {
                    throw new IllegalArgumentException("Duplicate sample_name: ${sample_name}")
                }

                def raw_path = row.mzML?.trim()
                if (!raw_path) {
                    throw new IllegalArgumentException("Missing mzML path for ${sample_name}")
                }
                def mzml = file(raw_path.startsWith('/') ? raw_path : "${csv.parent}/${raw_path}")
                if (!mzml.exists() || !mzml.name.toLowerCase().endsWith('.mzml')) {
                    throw new IllegalArgumentException("Missing or invalid mzML for ${sample_name}: ${mzml}")
                }
                if (!input_paths.add(mzml.toRealPath().toString())) {
                    throw new IllegalArgumentException("mzML file listed more than once: ${mzml}")
                }
                if (!mzml_basenames.add(mzml.baseName)) {
                    throw new IllegalArgumentException("mzML basenames must be unique across samples: ${mzml.baseName}")
                }

                tuple(sample_name, mzml)
            }
        }
}

log.info """\
        =========================================================
        P I P E L I N E   S E A R C H   P R O T E O M I C   D I A
        =========================================================
        Boutros Lab

        Current Configuration:
        - pipeline:
            name: ${workflow.manifest.name}
            version: ${workflow.manifest.version}

        - input CSV: ${params.input_csv}
        - decoy_database: ${params.decoy_database}
        - output: ${params.output_dir_base}

        Starting workflow...
        """.stripIndent()

workflow {
    validated_samples = readInputMzML(params.input_csv)

    write_MSFraggerParams(
        validated_samples.map { params.MSFragger },
        params.decoy_prefix,
        file(params.decoy_database)
    )

    search_database_MSFragger(
        validated_samples.flatMap { it },
        file(params.decoy_database),
        write_MSFraggerParams.out.params_file,
        file(params.msfragger_executable)
    )

    pepxml_with_mzml = search_database_MSFragger.out.search_results
        .join(validated_samples.flatMap { it })
        .map { sample_name, pepxml_files, pin_file, mzml_file ->
            tuple(sample_name, pepxml_files, mzml_file)
        }

    convert_pepXML2idXML_MSFragger(pepxml_with_mzml)

    search_files = search_database_MSFragger.out.search_results
        .flatMap { sample_name, pepxml_files, pin_file ->
            def ranks = pepxml_files instanceof Collection ? pepxml_files : [pepxml_files]
            (ranks + [pin_file]).collect { result_file -> tuple(sample_name, result_file) }
        }
    idxml_files = convert_pepXML2idXML_MSFragger.out.idxml
        .map { sample_name, idxml_file -> tuple(sample_name, idxml_file) }
    calculate_SHA512(search_files.mix(idxml_files))
}
