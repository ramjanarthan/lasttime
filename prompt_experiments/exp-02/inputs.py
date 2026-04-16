import apple_fm_sdk as fm
from dataclasses import dataclass

DEFAULT_MEMORY_PROMPT = """Classify this sentence as a fact about the user. Only return is_fact = true when the sentence describes something the user personally did or experienced, e.g. \"Remember that I ate lunch at noon.\" -> is_fact true. If the sentence is a question, a prediction, or general knowledge, set is_fact = false."""
DEFAULT_QUERY_PROMPT = """Classify this sentence as a personal question about when the user last did something. Only return is_question = true when the sentence is a first-person time question (contains when / last / today / yesterday) about the user, e.g. \"When did I last visit the office?\" -> is_question true. General knowledge, requests about others, or future planning should return false."""

DEFAULT_MEMORY_SESSION_INSTRUCTIONS = "You are a careful classifier that labels inputs as personal facts only when the sentence describes what the user personally did or experienced. Example: \"Remember that I ran a mile yesterday\" -> is_fact true; is_fact false for questions or general knowledge."

DEFAULT_QUERY_SESSION_INSTRUCTIONS = "You are a careful classifier that labels inputs as personal 'when' questions only when the user asks about when they last did something. Example: \"When did I last drink coffee?\" -> is_question true; is_question false for general knowledge questions or future plans."
 
@fm.generable("Classification result for whether an input is a fact to remember")
class FactClassification:
    is_fact: bool
    fact: str


@fm.generable("Classification result for whether an input is a personal question about the user")
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
