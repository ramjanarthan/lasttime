import apple_fm_sdk as fm
from dataclasses import dataclass

DEFAULT_MEMORY_PROMPT = """Classify this sentence as a fact about the user.

Return is_fact = true only when all of the following are satisfied:
1. The sentence is first-person and describes something the user already did or experienced in the past.
2. It contains explicit timing or memory cues such as yesterday, this morning, last night, remember, record, note, or keep in mind.
3. It is not presented as a question, a future plan, speculation, or general knowledge statement.
4. Sentences that start with question words (when, where, how) but have no question mark should still be treated as memories when they describe a past event.

Examples:
- "Remember that I replaced my laptop battery this afternoon." -> is_fact true
- "When did I last go to the gym?" -> is_fact false

When is_fact = true, set fact to the cleaned memory text; otherwise set fact to an empty string."""
DEFAULT_QUERY_PROMPT = """Classify this sentence as a personal question about when the user last did something.

Return is_question = true only when all of the following are satisfied:
1. The sentence is clearly a question and ends with a question mark (if there is no '?', return false regardless of other words).
2. It mentions the user (I/my/me) and asks with timing words such as when, last, previously, earlier, or ago.
3. It is not about future planning, general knowledge, or instructions to remember something (remember, note, record, keep in mind).

Examples:
- "When did I last eat a sandwich?" -> is_question true
- "Note that I brushed my teeth at 12pm yesterday." -> is_question false

When is_question = true, set question to the canonical question text; otherwise set question to an empty string."""

DEFAULT_MEMORY_SESSION_INSTRUCTIONS = "You are a careful classifier that labels inputs as personal facts only when the sentence describes a discrete thing the user personally did or experienced in the past and has clear timing or memory cues. Explicit memory prompts (remember, note, record, keep in mind) should return is_fact = true even if they include words like when. If the sentence is a question, a plan, or a general knowledge statement, set is_fact = false."

DEFAULT_QUERY_SESSION_INSTRUCTIONS = "You are a careful classifier that labels inputs as personal 'when' questions only when the sentence ends with a question mark, mentions the user, and is about when they last did something. Sentences that start with memory cues or lack a question mark must return is_question = false."""
 
@fm.generable("Classification result for whether an input is a fact to remember")
class FactClassification:
    is_fact: bool
    fact: str
    confidence_score: int


@fm.generable("Classification result for whether an input is a personal question about the user")
class QuestionClassification:
    is_question: bool
    question: str
    confidence_score: int

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
