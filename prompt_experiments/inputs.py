from dataclasses import dataclass

DEFAULT_MEMORY_PROMPT = "Classify this sentence as a fact about the user. Questions are not facts."
DEFAULT_QUERY_PROMPT = "Classify this sentence as a personal question about the user. General knowledge questions and future plans are not valid."
DEMO_MEMORIES = [
    "I ate coffee at the Bakery on 20th street",
    "I brushed my teeth last Tuesday",
    "Rahul went to the gym on monday",
]


@dataclass(frozen=True)
class FactClassification:
    is_fact: bool
    fact: str


@dataclass(frozen=True)
class QuestionClassification:
    is_question: bool
    question: str


@dataclass(frozen=True)
class UserQueryClassification:
    kind: str
    value: str = ""

    @classmethod
    def memory(cls, fact: str) -> "UserQueryClassification":
        return cls(kind="memory", value=fact)

    @classmethod
    def query(cls, question: str) -> "UserQueryClassification":
        return cls(kind="query", value=question)

    @classmethod
    def invalid(cls) -> "UserQueryClassification":
        return cls(kind="invalid", value="")
