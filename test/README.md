# Pipeline tests

The UCLA NFTest integration cases search DIA data with MSFragger. The
`test-integration-msfragger` case keeps the legacy two-column CSV and runs two
single-fraction samples. The `test-integration-fractions` case runs three
fractions for each of two samples and merges their idXMLs.
The target-decoy FASTA and MSFragger JAR are configured in each case's
`test.config`; all fixture paths resolve beneath `TEST_DATA_DIR`.

The FASTA must contain target and decoy sequences compatible with the
configured `decoy_prefix`. Set `TEST_DATA_DIR` in the Git-ignored `.env` file;
`.env-template` pins the Nextflow version and syntax parser. Run from a Slurm
job with NFTest and Nextflow available:

```bash
bash test/run-nftest.sh test-integration-msfragger
bash test/run-nftest.sh test-integration-fractions
```

The runner writes NFTest files, Nextflow work files, and pipeline output under
`/scratch/$SLURM_JOB_ID/<test-case>`. Each case retains its work directory and
intermediate MSFragger parameters for inspection.
The search publishes the PIN file and every pepXML rank file produced for each
mzML, retaining MSFragger's output filenames. The conversion process then
publishes one `per_fraction/<mzML basename>_MSFragger.idXML` containing all
ranks for that fraction. Each identification has `id_merge_index = 0` for its
sole source mzML and retains the original rank and pepXML filename.
IDMerger publishes one `<sample_name>_MSFragger.idXML` per sample. Each
published pepXML, PIN, and idXML file has a `.sha512` sidecar beside it.
