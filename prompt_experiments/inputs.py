import apple_fm_sdk as fm
from dataclasses import dataclass
from enum import Enum

DEFAULT_MEMORY_PROMPT = "Classify this sentence as a fact about the user. Questions are not facts."
DEFAULT_QUERY_PROMPT = "Classify this sentence as a personal question about the user. General knowledge questions and future plans are not valid."

DEFAULT_MEMORY_SESSION_INSTRUCTIONS = "You are a helpful assistant that classifies user inputs as either facts to remember or not. Only classify something as a fact if it is a statement about something that the user did. Do not classify general knowledge or questions as facts."

DEFAULT_QUERY_SESSION_INSTRUCTIONS = "You are a helpful assistant that classifies user inputs as either personal questions or not. Only classify something as a personal question if it is a question about when was the last time the user did something. Do not classify general knowledge questions or future plans as personal questions."

DEFAULT_INSTRUCTION = "You are a text classifier. Classify the user input into one of the following categories: 1) a fact to remember about the user, 2) a personal question about when the user last did something, or 3) invalid input that is neither. Only classify something as a fact if it's a request to save/remember something that the user did. Only classify something as a personal question if it is a question about when was the last time the user did something. General knowledge, future plans, and questions that are not about when the user last did something should be classified as invalid."
 
@fm.generable("Type of statement the user input is")
class UserInputType(Enum):
    MEMORY: str = "memory"
    QUERY: str = "query"
    INVALID: str = "invalid"

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
