"""Generate a stable, Python-ready dataset for prompt experimentation."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List


@dataclass(frozen=True)
class RawEntry:
    text: str
    kind: str
    canonical: str | None = None


def build_dataset() -> List[RawEntry]:
    memory_entries = [
        RawEntry(
            "Remember that I ate a cream sandwich today at noon.",
            kind="memory",
            canonical="I ate a cream sandwich today at noon",
        ),
        RawEntry(
            "Note that I brushed my teeth at 12pm yesterday.",
            kind="memory",
            canonical="I brushed my teeth at 12pm yesterday",
        ),
        RawEntry(
            "I went for a hike last Sunday morning.",
            kind="memory",
            canonical="I went for a hike last Sunday morning",
        ),
        RawEntry(
            "Just so you know, I started a new book this evening.",
            kind="memory",
            canonical="I started a new book this evening",
        ),
        RawEntry(
            "I drank coffee at the new roastery on Friday.",
            kind="memory",
            canonical="I drank coffee at the new roastery on Friday",
        ),
        RawEntry(
            "Put this in memory: I finished the quarterly report on Thursday.",
            kind="memory",
            canonical="I finished the quarterly report on Thursday",
        ),
        RawEntry(
            "I recorded that I ran eight miles this morning.",
            kind="memory",
            canonical="I ran eight miles this morning",
        ),
        RawEntry(
            "Remember, I had dinner with Julia on Tuesday.",
            kind="memory",
            canonical="I had dinner with Julia on Tuesday",
        ),
        RawEntry(
            "This afternoon I replaced my laptop battery.",
            kind="memory",
            canonical="I replaced my laptop battery this afternoon",
        ),
    ]

    query_entries = [
        RawEntry("When did I last eat a sandwich?", kind="query", canonical="When did I last eat a sandwich?"),
        RawEntry("Can you remind me when I brushed my teeth last?", kind="query", canonical="Can you remind me when I brushed my teeth last?"),
        RawEntry("When was the last time I jogged in the park?", kind="query", canonical="When was the last time I jogged in the park?"),
        RawEntry(
            "I can’t recall—when did I take my medication yesterday?",
            kind="query",
            canonical="When did I take my medication yesterday?",
        ),
        RawEntry("When did I go to the gym earlier this week?", kind="query", canonical="When did I go to the gym earlier this week?"),
        RawEntry("When did I drink coffee at the office?", kind="query", canonical="When did I drink coffee at the office?"),
        RawEntry("When did I last visit San Francisco?", kind="query", canonical="When did I last visit San Francisco?"),
        RawEntry("When was the last time I met with the product team?", kind="query", canonical="When was the last time I met with the product team?"),
        RawEntry("When exactly did I read the technical doc?", kind="query", canonical="When exactly did I read the technical doc?"),
        RawEntry("When did I last eat pizza", kind="query", canonical="When did I last eat pizza"),
    ]

    invalid_entries = [
        RawEntry("What is the capital of England?", kind="invalid"),
        RawEntry("I am thinking about lunch.", kind="invalid"),
        RawEntry("How did the meeting go?", kind="invalid"),
        RawEntry("When will we go on vacation?", kind="invalid"),
        RawEntry("Where did I leave the keys?", kind="invalid"),
        RawEntry("I am hungry and want to eat.", kind="invalid"),
        RawEntry("Tell me when to leave.", kind="invalid"),
        RawEntry("When was the moon landing?", kind="invalid"),
    ]

    return [*memory_entries, *query_entries, *invalid_entries]


def write_dataset(entries: Iterable[RawEntry], path: Path | None = None) -> None:
    path = path or Path(__file__).with_name("dataset_entries.py")
    header = """"""  # placeholder for actual header to avoid issues? need triple quotes? We'll add actual header: '# Auto-generated dataset' etc.****
