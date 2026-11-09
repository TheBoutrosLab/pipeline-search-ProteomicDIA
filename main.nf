#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { write_MSFraggerParams } from './module/write_MSFraggerParams.nf'
include { search_database_MSFragger } from './module/search_database_MSFragger.nf'
include { convert_pepXML2idXML_MSFragger } from './module/convert_pepXML2idXML_MSFragger.nf'
include { merge_idXML_MSFragger } from './module/merge_idXML_MSFragger.nf'
include { calculate_SHA512 } from './module/calculate_SHA512.nf'

/** Read one mzML per sample and fraction from the input CSV. */
def readInputMzML(String input_csv) {
    def csv = file(input_csv)

    return Channel.fromPath(csv)
        .splitCsv(header: true)
        .toList()
        .map { rows ->
            if (!rows) {
                throw new IllegalArgumentException("Input CSV has no samples: ${csv}")
            }

            def columns = rows[0].keySet() as Set
            def legacy_columns = ['sample_name', 'mzML'] as Set
            def fraction_columns = ['sample_name', 'fraction', 'mzML'] as Set
            if (!(columns == legacy_columns || columns == fraction_columns)) {
                throw new IllegalArgumentException('Input CSV must have sample_name,mzML or sample_name,fraction,mzML columns')
            }

            def sample_fractions = [] as Set
            def input_paths = [] as Set
            def mzml_basenames = [] as Set
            rows.collect { row ->
                if (row.keySet() != columns) {
                    throw new IllegalArgumentException('Input CSV rows must have the same columns')
                }

                def sample_name = row.sample_name?.trim()
                if (!(sample_name ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/)) {
                    throw new IllegalArgumentException("Invalid sample_name: ${row.sample_name}")
                }
                def fraction = columns == fraction_columns ? row.fraction?.trim() : '1'
                if (!(fraction ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/)) {
                    throw new IllegalArgumentException("Invalid fraction for ${sample_name}: ${row.fraction}")
                }
                if (!sample_fractions.add([sample_name, fraction])) {
                    throw new IllegalArgumentException("Duplicate fraction ${fraction} for ${sample_name}")
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
                if (!mzml_basenames.add(mzml.baseName.toLowerCase())) {
                    throw new IllegalArgumentException("mzML basenames must be unique across samples: ${mzml.baseName}")
                }

                tuple(sample_name, fraction, mzml)
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
        .map { sample_name, fraction, mzml_file, pepxml_files, pin_file ->
            tuple(sample_name, fraction, pepxml_files, mzml_file)
        }

    convert_pepXML2idXML_MSFragger(pepxml_with_mzml)

    fraction_idxmls = convert_pepXML2idXML_MSFragger.out.idxml
        .map { sample_name, fraction, idxml_file -> tuple(sample_name, idxml_file) }
        .groupTuple()
    merge_idXML_MSFragger(fraction_idxmls)

    search_files = search_database_MSFragger.out.search_results
        .flatMap { sample_name, fraction, mzml_file, pepxml_files, pin_file ->
            def ranks = pepxml_files instanceof Collection ? pepxml_files : [pepxml_files]
            (ranks + [pin_file]).collect { result_file -> tuple(sample_name, 'search', result_file) }
        }
    fraction_files = convert_pepXML2idXML_MSFragger.out.idxml
        .map { sample_name, fraction, idxml_file -> tuple(sample_name, 'fraction', idxml_file) }
    merged_files = merge_idXML_MSFragger.out.merged
        .map { sample_name, idxml_file -> tuple(sample_name, 'merged', idxml_file) }
    calculate_SHA512(search_files.mix(fraction_files, merged_files))
}
