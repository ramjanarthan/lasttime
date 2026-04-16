import apple_fm_sdk as fm
from dataclasses import dataclass

DEFAULT_MEMORY_PROMPT = """Classify this sentence as a fact about the user. Return is_fact = true only when the sentence describes something the user actually did or experienced in the past and mentions timing language (e.g., "Remember that I ate lunch at noon.") or explicit memory cues. Return false for questions, general knowledge, future planning, or ongoing thoughts (e.g., "I am thinking about lunch.")."""
DEFAULT_QUERY_PROMPT = """Classify this sentence as a personal question about when the user last did something. Return is_question = true only when the sentence addresses the user (I/my) and asks about a past event with timing language such as did, last, previously, earlier, yesterday, or ago. Return false for future planning/future tense (e.g., "When should I plan to refuel my car next month?") or general knowledge."""

DEFAULT_MEMORY_SESSION_INSTRUCTIONS = "You are a careful classifier that labels inputs as personal facts only when the sentence describes a specific thing the user did or experienced and includes past timing language or memory cues. Example: \"Remember that I ran a mile yesterday\" -> is_fact true; \"I am thinking about lunch\" -> is_fact false."

DEFAULT_QUERY_SESSION_INSTRUCTIONS = "You are a careful classifier that labels inputs as personal 'when' questions only when the user asks about when they last did something. Example: \"When did I last drink coffee?\" -> is_question true; \"When will we go on vacation?\" -> is_question false."
 
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
