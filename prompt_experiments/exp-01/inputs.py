import apple_fm_sdk as fm
from dataclasses import dataclass

DEFAULT_MEMORY_PROMPT = """Classify this sentence as a fact about the user. Only mark something as a fact when it is a statement about what the user actually did or experienced in the past; questions, predictions, general knowledge, or third-party statements should all return is_fact = false."""
DEFAULT_QUERY_PROMPT = """Classify this sentence as a personal question related to when the user last did something. Only mark a question as personal if it mentions the user (I/my/me) and contains an explicit time request (when, last time, today, yesterday, etc.); general knowledge, future planning, or questions about others should return is_question = false."""

DEFAULT_MEMORY_SESSION_INSTRUCTIONS = "You are a careful classifier that labels inputs as personal facts only when the sentence describes something the user personally did or experienced. If the input is a question, a hypothetical, a future plan, or a statement about anyone else, then set is_fact = false."

DEFAULT_QUERY_SESSION_INSTRUCTIONS = "You are a careful classifier that labels inputs as personal 'when' questions only when the user is asking about when they last did something. If the sentence lacks a direct time request or refers to other people or general knowledge, set is_question = false."
 
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
