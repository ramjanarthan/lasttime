import apple_fm_sdk as fm
from dataclasses import dataclass

DEFAULT_MEMORY_PROMPT = """Classify this sentence as a fact about the user to remember, following these criteria: 
1. The sentence is first-person and describes something the user already did or experienced in the past.
2. It contains explicit indications to remember something, such as the words remember, note, record, or keep in mind.
3. The statement could be a request to remember something phrased as a question.

Examples <Input> : <classification as fact>
- "Remember that I replaced my laptop battery this afternoon." : true
- "Can you note that I brushed my teeth at 12pm yesterday?" : true
- "When did I last go to the gym?" : false
"""

DEFAULT_QUERY_PROMPT = """Classify this sentence as a personal question about when the user last did something, following these criteria:
1. The sentence is clearly a question, but it is NOT a request to remember something phrased as a question.
2. It mentions the user (I/my/me) and asks with timing words such as when and last.
3. It is not about future planning, general knowledge, or instructions to remember something (remember, note, record, keep in mind).

Examples <Input> : <classification as question>
- "When did I last eat a sandwich?" : true
- "Note that I brushed my teeth at 12pm yesterday." : false
"""

DEFAULT_MEMORY_SESSION_INSTRUCTIONS = "You are a careful classifier that labels inputs as personal facts only when the sentence describes a discrete thing the user personally did or experienced in the past and has clear timing or memory cues"

DEFAULT_QUERY_SESSION_INSTRUCTIONS = "You are a careful classifier that labels inputs as personal 'when' questions only when the sentence ends with a question mark, mentions the user, and is about when they last did something"
 
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
