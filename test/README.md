# Pipeline tests

The UCLA NFTest integration case runs the unfractionated DIA search through
MSFragger. Its mzML fixtures are listed in
`test/test-integration-msfragger/input.csv`. The target-decoy FASTA and
MSFragger JAR are configured in `test/test-integration-msfragger/test.config`;
all fixture paths resolve beneath `TEST_DATA_DIR`.

The FASTA must contain target and decoy sequences compatible with the
configured `decoy_prefix`. Set `TEST_DATA_DIR` in the Git-ignored `.env` file;
`.env-template` pins the Nextflow version and syntax parser. Run from a Slurm
job with NFTest and Nextflow available:

```bash
bash test/run-nftest.sh test-integration-msfragger
```

The runner writes NFTest files, Nextflow work files, and pipeline output under
`/scratch/$SLURM_JOB_ID/test-integration-msfragger`. The case retains its work
directory and intermediate MSFragger parameters for inspection.
The search publishes the PIN file and every pepXML rank file produced for each
mzML, retaining MSFragger's output filenames. The conversion process then
publishes one `<sample_name>_MSFragger.idXML` containing all ranks for that
sample. Each identification records the source mzML as `file_origin`, plus its
original rank and pepXML filename in separate metadata fields.
Each published pepXML, PIN, and idXML file also has a `.sha512` sidecar.
