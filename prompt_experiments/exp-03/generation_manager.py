"""Python mirror of the Swift generation manager for experimentation."""
import asyncio
from typing import Callable, List, Optional
import apple_fm_sdk as fm
from inputs import *

class MemoryStore:
    """Simple in-memory store mirroring lasttime/Manager/MemoryManager.swift."""

    def __init__(self, seed: Optional[List[str]] = None) -> None:
        self.memories: List[str] = list(seed or [])

    def get_relevant_memories(self, prompt: str) -> List[str]:
        target_words = {word.strip(".,?!") for word in prompt.lower().split() if word}
        relevant: List[str] = []
        for memory in self.memories:
            memory_words = {word.strip(".,?!") for word in memory.lower().split()}
            intersection = memory_words & target_words
            if len(intersection) > 2:
                relevant.append(memory)
        return relevant

    def save_memory(self, memory: str) -> None:
        self.memories.append(memory)


class GenerationManager:
    """Encapsulates prompt tuning & evaluation logic, currently using heuristics."""

    def __init__(
        self,
        memory_store: Optional[MemoryStore] = None,
    ) -> None:
        self.memory_store = memory_store or MemoryStore()
        self.memory_prompt = DEFAULT_MEMORY_PROMPT
        self.query_prompt = DEFAULT_QUERY_PROMPT

    async def classify_as_memory(self, text: str) -> FactClassification:
        cleaned = text.strip()
        session = fm.LanguageModelSession(instructions=DEFAULT_MEMORY_SESSION_INSTRUCTIONS)
        prompt = self._build_prompt(self.memory_prompt, cleaned)
        return await session.respond(prompt, generating=FactClassification)

    async def classify_as_query(self, text: str) -> QuestionClassification:
        cleaned = text.strip()
        session = fm.LanguageModelSession(instructions=DEFAULT_QUERY_SESSION_INSTRUCTIONS)
        prompt = self._build_prompt(self.query_prompt, cleaned)
        return await session.respond(prompt, generating=QuestionClassification)

    async def classify_input(self, text: str) -> UserQueryClassification:
        memory_result = await self.classify_as_memory(text)
        heuristic_memory_classification = self._heuristic_memory(text)

        question_result = await self.classify_as_query(text)
        heuristic_question_classification = self._heuristic_query(text)

        if heuristic_question_classification.is_question:
            question_text = question_result.question or text.strip()
            return UserQueryClassification.query(question_text)
        if heuristic_memory_classification.is_fact:
            fact_text = memory_result.fact or text.strip()
            return UserQueryClassification.memory(fact_text)
        return UserQueryClassification.invalid()

    async def generate_output(self, text: str) -> str:
        classification = await self.classify_input(text)
        if classification.kind == "memory":
            self.memory_store.save_memory(classification.value)
            return f"Thanks, I noted: {classification.value}"
        if classification.kind == "query":
            memories = self.memory_store.get_relevant_memories(classification.value)
            return memories[0] if memories else "I couldn't find a relevant memory for that question."
        return "This isn't a valid input type for me"

    def _heuristic_memory(self, text: str) -> FactClassification:
        cleaned = text.strip()
        normalized = cleaned.replace("—", " ").replace("–", " ")
        lower = normalized.lower()
        words = {word.strip(".,?!'\"") for word in lower.split() if word}
        memory_cues = (
            "remember",
            "note",
            "record",
            "keep in mind",
            "remind you",
            "just so you know",
            "put this in memory",
            "let me remind you",
        )
        contains_cue = any(phrase in lower for phrase in memory_cues)
        time_tokens = {
            "yesterday",
            "today",
            "ago",
            "last",
            "monday",
            "tuesday",
            "wednesday",
            "thursday",
            "friday",
            "saturday",
            "sunday",
            "morning",
            "afternoon",
            "evening",
            "night",
            "tonight",
            "noon",
            "week",
            "month",
            "year",
            "earlier",
        }
        time_phrases = (
            "this morning",
            "this afternoon",
            "this evening",
            "last night",
            "earlier today",
            "earlier this week",
        )
        contains_time = bool(words & time_tokens) or any(phrase in lower for phrase in time_phrases)
        first_person = bool(words & {"i", "my"})
        is_question = cleaned.endswith("?")
        is_fact = not is_question and (contains_cue or (first_person and contains_time))
        return FactClassification(is_fact=is_fact, fact=cleaned if is_fact else "")

    def _heuristic_query(self, text: str) -> QuestionClassification:
        cleaned = text.strip()
        normalized = cleaned.replace("—", " ").replace("–", " ")
        lower = normalized.lower()
        words = {word.strip(".,?!'\"") for word in lower.split() if word}
        contains_when = "when" in words
        is_question = cleaned.endswith("?") or lower.startswith("when")
        past_markers = {
            "did",
            "last",
            "ago",
            "previous",
            "previously",
            "earlier",
            "yesterday",
            "was",
            "had",
            "before",
        }
        future_markers = {
            "will",
            "should",
            "plan",
            "plans",
            "next",
            "tomorrow",
            "later",
            "future",
            "planning",
            "going",
        }
        personal = bool(words & {"i", "my"})
        has_past = bool(words & past_markers)
        has_future = bool(words & future_markers) or "plan to" in lower or "plan on" in lower
        if contains_when and personal and has_past and not has_future and is_question:
            return QuestionClassification(is_question=True, question=cleaned)
        return QuestionClassification(is_question=False, question="")

    def _build_prompt(self, instruction: str, text: str) -> str:
        return f"{instruction}\n------------\n{text}."

# def main() -> None:
#     manager = GenerationManager()
#     results = asyncio.run(manager.classify_input("When did I last go to the gym?"))
#     print(results)

# if __name__ == "__main__":
#     main()
