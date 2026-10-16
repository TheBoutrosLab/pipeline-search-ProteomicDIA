"""Combine one sample's MSFragger DIA pepXML ranks into a single idXML."""

import argparse
import re
from pathlib import Path
import pyopenms as oms


def pepxml_ranks(input_dir: Path, mzml: Path) -> list[tuple[int, Path]]:
    """Find all rank files for this mzML, rejecting ambiguous inputs."""
    stem = mzml.stem
    matches = []
    for path in input_dir.iterdir():
        if (
            not path.is_file()
            or not path.name.startswith(stem)
            or not path.name.endswith(".pepXML")
        ):
            continue
        suffix = path.name[len(stem) :]
        if suffix == ".pepXML":
            rank = 1
        else:
            match = re.fullmatch(r"_rank([1-9][0-9]*)\.pepXML", suffix)
            if not match:
                continue
            rank = int(match.group(1))
        matches.append((rank, path))

    if not matches:
        raise ValueError(f"No MSFragger pepXML rank files found for {mzml.name} in {input_dir}")
    ranks = [rank for rank, _ in matches]
    if len(ranks) != len(set(ranks)):
        raise ValueError(f"Duplicate pepXML ranks for {mzml.name}: {sorted(ranks)}")
    return sorted(matches)


def text(value: object) -> str:
    """Decode a pyOpenMS string value into regular Python text."""
    return value.decode("utf-8") if isinstance(value, bytes) else str(value)


def convert(mzml: Path, input_dir: Path, output: Path) -> None:
    """Combine all ranked pepXML identifications for one mzML into idXML."""
    if not mzml.is_file():
        raise FileNotFoundError(mzml)
    ranks = pepxml_ranks(input_dir, mzml)

    # The mzML lookup supplies native spectrum references and retention times
    # when the pepXML contains only scan numbers. Peak arrays are not needed.
    mzml_reader = oms.MzMLFile()
    options = oms.PeakFileOptions()
    options.setMetadataOnly(True)
    mzml_reader.setOptions(options)
    experiment = oms.MSExperiment()
    mzml_reader.load(str(mzml), experiment)
    lookup = oms.SpectrumMetaDataLookup()
    lookup.readSpectra(experiment, r"scan=(?<SCAN>\d+)")

    all_proteins = []
    all_peptides = oms.PeptideIdentificationList()
    for rank, pepxml in ranks:
        proteins = []
        peptides = oms.PeptideIdentificationList()
        reader = oms.PepXMLFile()
        reader.keepNativeSpectrumName(True)
        reader.setParseUnknownScores(True)
        reader.load(str(pepxml), proteins, peptides, mzml.name, lookup)
        if not proteins:
            raise ValueError(f"No identification run found in {pepxml}")

        identifiers = {}
        for index, protein in enumerate(proteins, start=1):
            old_id = text(protein.getIdentifier())
            if old_id in identifiers:
                raise ValueError(f"Repeated protein run identifier in {pepxml}: {old_id}")
            new_id = f"{mzml.stem}_MSFragger_rank{rank}_run{index}"
            identifiers[old_id] = new_id
            protein.setIdentifier(new_id)
            protein.setPrimaryMSRunPath([mzml.name.encode("utf-8")], False)
            protein.setMetaValue("msfragger_rank", rank)
            all_proteins.append(protein)

        for peptide in peptides:
            old_id = text(peptide.getIdentifier())
            if old_id not in identifiers:
                raise ValueError(
                    f"Peptide run identifier {old_id!r} has no protein run in {pepxml}"
                )
            peptide.setIdentifier(identifiers[old_id])
            peptide.setMetaValue("msfragger_rank", rank)
            peptide.setMetaValue("file_origin", mzml.name)
            peptide.setMetaValue("msfragger_pepxml", pepxml.name)
            all_peptides.push_back(peptide)

    oms.IdXMLFile().store(str(output), all_proteins, all_peptides)
    print(
        f"Wrote {len(all_peptides)} peptide identifications "
        f"from {len(ranks)} pepXML rank file(s) to {output}"
    )


def main() -> None:
    """Parse command-line arguments and run the conversion."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mzml", required=True, type=Path)
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    convert(args.mzml, args.input_dir, args.output)


if __name__ == "__main__":
    main()
