# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-10-16

### Added

- First unfractionated DIA search workflow using a separately supplied MSFragger JAR and target-decoy FASTA.
- Native MSFragger parameter generation from a dedicated configuration namespace, with schema validation and optional intermediate-file publication.
- CSV input with one mzML per sample; unfiltered pepXML rank files and PIN output for each search.
- pyOpenMS conversion of all pepXML ranks into one idXML per sample, retaining mzML origin and rank provenance.
- UCLA NFTest integration case and a runner that retains test output and work files under `/scratch`.
- SHA-512 checksum sidecars for every pepXML rank, PIN, and idXML result.

