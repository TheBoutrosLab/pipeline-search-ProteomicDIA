# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.3] - 2026-11-20

### Changed

- Migrate the pipeline license from GPL to BSD 3-Clause and update license documentation; shared code and third-party tools retain their respective licenses.

## [0.2.2] - 2026-11-10

### Fixed

- Use `id_merge_index` as the sole peptide origin annotation and omit redundant pepXML metadata so IDRipper can split fractions.

## [0.2.1] - 2026-11-09

### Fixed

- Preserve fraction-to-mzML indices in merged DIA idXML so downstream mzTab export succeeds.

## [0.2.0] - 2026-11-09

### Added

- Add MSFragger precursor charge range and charge override settings with schema validation and usage guidance.
- Support offline multi-fraction DIA samples with per-fraction searches and a merged sample idXML.

## [0.1.1] - 2026-10-24

### Fixed

- Preserve separate, browsable process logs for every sample and task, including checksum calculations.

## [0.1.1-rc.1] - 2026-10-17

### Fixed

- Merge MSFragger DIA pepXML ranks into a single protein identification run per mzML so downstream OpenMS tools can process the idXML and export mzTab.

## [0.1.0] - 2026-10-16

### Added

- First unfractionated DIA search workflow using a separately supplied MSFragger JAR and target-decoy FASTA.
- Native MSFragger parameter generation from a dedicated configuration namespace, with schema validation and optional intermediate-file publication.
- CSV input with one mzML per sample; unfiltered pepXML rank files and PIN output for each search.
- pyOpenMS conversion of all pepXML ranks into one idXML per sample, retaining mzML origin and rank provenance.
- UCLA NFTest integration case and a runner that retains test output and work files under `/scratch`.
- SHA-512 checksum sidecars for every pepXML rank, PIN, and idXML result.

[0.1.0]: https://github.com/TheBoutrosLab/pipeline-search-ProteomicDIA/releases/tag/v0.1.0
[0.1.1]: https://github.com/TheBoutrosLab/pipeline-search-ProteomicDIA/compare/v0.1.1-rc.1...v0.1.1
[0.1.1-rc.1]: https://github.com/TheBoutrosLab/pipeline-search-ProteomicDIA/compare/v0.1.0...v0.1.1-rc.1
[0.2.0]: https://github.com/TheBoutrosLab/pipeline-search-ProteomicDIA/compare/v0.1.1...v0.2.0
[0.2.1]: https://github.com/TheBoutrosLab/pipeline-search-ProteomicDIA/compare/v0.2.0...v0.2.1
[0.2.2]: https://github.com/TheBoutrosLab/pipeline-search-ProteomicDIA/compare/v0.2.1...v0.2.2
[0.2.3]: https://github.com/TheBoutrosLab/pipeline-search-ProteomicDIA/compare/v0.2.2...v0.2.3
[unreleased]: https://github.com/TheBoutrosLab/pipeline-search-ProteomicDIA/compare/v0.2.3...HEAD
