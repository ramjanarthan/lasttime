"""Generate the shared JSON dataset for the prompt experiment harness."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, List

DATASET_PATH = Path(__file__).parent / "dataset.json"


@dataclass(frozen=True)
class DatasetEntry:
    text: str
    kind: str
    canonical: str | None = None


def build_entries() -> List[DatasetEntry]:
    memory_entries = [
        DatasetEntry(
            text="Remember that I ate a cream sandwich today at noon.",
            kind="memory",
            canonical="I ate a cream sandwich today at noon",
        ),
        DatasetEntry(
            text="Note that I brushed my teeth at 12pm yesterday.",
            kind="memory",
            canonical="I brushed my teeth at 12pm yesterday",
        ),
        DatasetEntry(
            text="I went for a hike last Sunday morning.",
            kind="memory",
            canonical="I went for a hike last Sunday morning",
        ),
        DatasetEntry(
            text="Just so you know, I started a new book this evening.",
            kind="memory",
            canonical="I started a new book this evening",
        ),
        DatasetEntry(
            text="I drank coffee at the new roastery on Friday.",
            kind="memory",
            canonical="I drank coffee at the new roastery on Friday",
        ),
        DatasetEntry(
            text="Put this in memory: I finished the quarterly report on Thursday.",
            kind="memory",
            canonical="I finished the quarterly report on Thursday",
        ),
        DatasetEntry(
            text="I recorded that I ran eight miles this morning.",
            kind="memory",
            canonical="I ran eight miles this morning",
        ),
        DatasetEntry(
            text="Remember, I had dinner with Julia on Tuesday.",
            kind="memory",
            canonical="I had dinner with Julia on Tuesday",
        ),
        DatasetEntry(
            text="This afternoon I replaced my laptop battery.",
            kind="memory",
            canonical="I replaced my laptop battery this afternoon",
        ),
        DatasetEntry(
            text="Keep in mind that I tried the new Italian place on Thursday night.",
            kind="memory",
            canonical="I tried the new Italian place on Thursday night",
        ),
        DatasetEntry(
            text="Record that I replaced the air filter this morning.",
            kind="memory",
            canonical="I replaced the air filter this morning",
        ),
        DatasetEntry(
            text="Let me remind you I finished the Swift draft yesterday evening.",
            kind="memory",
            canonical="I finished the Swift draft yesterday evening",
        ),
    ]

    query_entries = [
        DatasetEntry(text="When did I last eat a sandwich?", kind="query", canonical="When did I last eat a sandwich?"),
        DatasetEntry(text="Can you remind me when I brushed my teeth last?", kind="query", canonical="Can you remind me when I brushed my teeth last?"),
        DatasetEntry(text="When was the last time I jogged in the park?", kind="query", canonical="When was the last time I jogged in the park?"),
        DatasetEntry(
            text="I can’t recall—when did I take my medication yesterday?",
            kind="query",
            canonical="When did I take my medication yesterday?",
        ),
        DatasetEntry(text="When did I go to the gym earlier this week?", kind="query", canonical="When did I go to the gym earlier this week?"),
        DatasetEntry(text="When did I drink coffee at the office?", kind="query", canonical="When did I drink coffee at the office?"),
        DatasetEntry(text="When did I last visit San Francisco?", kind="query", canonical="When did I last visit San Francisco?"),
        DatasetEntry(text="When was the last time I met with the product team?", kind="query", canonical="When was the last time I met with the product team?"),
        DatasetEntry(text="When exactly did I read the technical doc?", kind="query", canonical="When exactly did I read the technical doc?"),
        DatasetEntry(text="When did I last eat pizza", kind="query", canonical="When did I last eat pizza"),
        DatasetEntry(text="When did I last see the sunrise over the bay?", kind="query", canonical="When did I last see the sunrise over the bay?"),
        DatasetEntry(text="Could you tell me when I previously visited the office?", kind="query", canonical="Could you tell me when I previously visited the office?"),
        DatasetEntry(text="Do you remember when I last paid my license renewal?", kind="query", canonical="Do you remember when I last paid my license renewal?"),
    ]

    invalid_entries = [
        DatasetEntry(text="What is the capital of England?", kind="invalid"),
        DatasetEntry(text="I am thinking about lunch.", kind="invalid"),
        DatasetEntry(text="How did the meeting go?", kind="invalid"),
        DatasetEntry(text="When will we go on vacation?", kind="invalid"),
        DatasetEntry(text="Where did I leave the keys?", kind="invalid"),
        DatasetEntry(text="I am hungry and want to eat.", kind="invalid"),
        DatasetEntry(text="Tell me when to leave.", kind="invalid"),
        DatasetEntry(text="When was the moon landing?", kind="invalid"),
        DatasetEntry(text="When is the first day of spring?", kind="invalid"),
        DatasetEntry(text="This is the time when we celebrate the solstice.", kind="invalid"),
        DatasetEntry(text="Tell me a fact about the moon.", kind="invalid"),
        DatasetEntry(text="When should I plan to refuel my car next month?", kind="invalid"),
    ]

    return [*memory_entries, *query_entries, *invalid_entries]


def write_dataset(entries: Iterable[DatasetEntry], path: Path | None = None) -> None:
    target = path or DATASET_PATH
    with target.open("w", encoding="utf-8") as handle:
        json.dump([asdict(entry) for entry in entries], handle, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    entries = build_entries()
    write_dataset(entries)
    print(f"Wrote {len(entries)} entries to {DATASET_PATH}")
