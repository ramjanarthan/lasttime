"""Python mirror of the Swift generation manager for experimentation."""
import asyncio
from dataclasses import dataclass
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
    """Encapsulates prompt tuning & evaluation logic relying solely on the model responses."""

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

    async def classify_input(self, text: str) -> "ClassificationDiagnostics":
        memory_result = await self.classify_as_memory(text)
        question_result = await self.classify_as_query(text)

        heuristic_classification = self._heuristic_classification(text)
        final_classification = self._choose_final_classification(
            heuristic_classification, memory_result, question_result, text
        )

        return ClassificationDiagnostics(
            final=final_classification,
            memory=memory_result,
            question=question_result,
        )

    async def generate_output(self, text: str) -> str:
        diagnostics = await self.classify_input(text)
        classification = diagnostics.final
        if classification.kind == "memory":
            self.memory_store.save_memory(classification.value)
            return f"Thanks, I noted: {classification.value}"
        if classification.kind == "query":
            memories = self.memory_store.get_relevant_memories(classification.value)
            return memories[0] if memories else "I couldn't find a relevant memory for that question."
        return "This isn't a valid input type for me"

    def _build_prompt(self, instruction: str, text: str) -> str:
        return f"{instruction}\n------------\n{text}."

    def _heuristic_classification(self, text: str) -> UserQueryClassification:
        lower = text.lower()
        normalized = text.strip()
        is_question = normalized.endswith("?")
        tokens = {word.strip(".,?!'") for word in lower.split()}
        first_person = bool(tokens & {"i", "my", "me"})
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
        time_words = {
            "yesterday",
            "today",
            "ago",
            "last",
            "earlier",
            "this",
            "morning",
            "afternoon",
            "evening",
            "night",
        }
        contains_time = bool(tokens & time_words)
        contains_cue = any(phrase in lower for phrase in memory_cues)
        if (contains_cue or (first_person and contains_time)) and not is_question:
            return UserQueryClassification.memory(normalized)
        if "when" in tokens and is_question and first_person:
            return UserQueryClassification.query(normalized)
        return UserQueryClassification.invalid()

    def _choose_final_classification(
        self,
        heuristic: UserQueryClassification,
        memory_result: FactClassification,
        question_result: QuestionClassification,
        text: str,
    ) -> UserQueryClassification:
        if heuristic.kind != "invalid":
            return heuristic
        if question_result.is_question:
            question_text = question_result.question or text.strip()
            return UserQueryClassification.query(question_text)
        if memory_result.is_fact:
            fact_text = memory_result.fact or text.strip()
            return UserQueryClassification.memory(fact_text)
        return UserQueryClassification.invalid()

@dataclass
class ClassificationDiagnostics:
    final: UserQueryClassification
    memory: FactClassification
    question: QuestionClassification


# def main() -> None:
#     manager = GenerationManager()
#     results = asyncio.run(manager.classify_input("When did I last go to the gym?"))
#     print(results)


# if __name__ == "__main__":
#     main()
