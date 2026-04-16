"""Simple harness that runs the generation manager against `dataset.json`."""
import argparse
import asyncio
import json
from pathlib import Path
from typing import Any, Dict, List

from generation_manager import GenerationManager

DATASET_PATH = Path(__file__).parent / "dataset.json"


def load_dataset(path: Path = DATASET_PATH) -> List[Dict[str, Any]]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


async def evaluate_entries(entries: List[Dict[str, Any]], manager: GenerationManager) -> List[Dict[str, Any]]:
    results: List[Dict[str, Any]] = []
    for entry in entries:
        classification = await manager.classify_input(entry["text"])
        results.append(
            {
                "text": entry["text"],
                "kind": entry["kind"],
                "canonical": entry.get("canonical"),
                "prediction": classification.kind,
            }
        )
    return results


def summarize(results: List[Dict[str, Any]], verbose: bool) -> None:
    total = len(results)
    correct = sum(1 for row in results if row["kind"] == row["prediction"])
    accuracy = correct / total if total else 0
    print(f"{correct}/{total} correct ({accuracy:.1%} accuracy)")
    mismatches = [row for row in results if row["kind"] != row["prediction"]]
    if mismatches:
        print(f"{len(mismatches)} mismatches")
        limit = mismatches if verbose else mismatches[:5]
        for row in limit:
            canonical = f" (canonical: {row['canonical']})" if row.get("canonical") else ""
            print(f"- text: {row['text']}{canonical} | expected: {row['kind']} | got: {row['prediction']}")
        if not verbose and len(mismatches) > 5:
            print(f"  ...and {len(mismatches) - 5} more")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Evaluate prompt heuristics against the shared dataset")
    parser.add_argument("--verbose", "-v", action="store_true", help="Print every mismatch")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    dataset = load_dataset()
    manager = GenerationManager()
    results = asyncio.run(evaluate_entries(dataset, manager))
    summarize(results, verbose=args.verbose)

if __name__ == "__main__":
    main()
