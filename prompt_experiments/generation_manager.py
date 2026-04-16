"""Python mirror of the Swift generation manager for experimentation."""

from __future__ import annotations

import asyncio
from dataclasses import dataclass
from typing import Callable, List, Optional
import apple_fm_sdk as fm
from inputs import *

class MemoryStore:
    """Simple in-memory store mirroring lasttime/Manager/MemoryManager.swift."""

    def __init__(self, seed: Optional[List[str]] = None) -> None:
        self.memories: List[str] = list(seed or DEMO_MEMORIES)

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


ModelSessionFactory = Callable[[], "fm.LanguageModelSession"] if fm else Callable[[], None]


class GenerationManager:
    """Encapsulates prompt tuning & evaluation logic, currently using heuristics."""

    def __init__(
        self,
        memory_store: Optional[MemoryStore] = None,
        session_factory: Optional[ModelSessionFactory] = None,
        use_heuristics_only: bool = True,
    ) -> None:
        self.memory_store = memory_store or MemoryStore()
        self.memory_prompt = DEFAULT_MEMORY_PROMPT
        self.query_prompt = DEFAULT_QUERY_PROMPT
        self._session_factory = session_factory
        self._use_model = not use_heuristics_only and fm is not None

    async def classify_as_memory(self, text: str) -> FactClassification:
        cleaned = text.strip()
        if self._use_model and self._session_factory:
            prompt = self._build_prompt(self.memory_prompt, cleaned)
            await self._respond_with_model(prompt)
            # TODO: parse FactClassification from the model response once we can control _Generable_ in Python.
        return self._heuristic_memory(cleaned)

    async def classify_as_query(self, text: str) -> QuestionClassification:
        cleaned = text.strip()
        if self._use_model and self._session_factory:
            prompt = self._build_prompt(self.query_prompt, cleaned)
            await self._respond_with_model(prompt)
            # TODO: parse QuestionClassification from the model response once we can control _Generable_ in Python.
        return self._heuristic_query(cleaned)

    async def classify_input(self, text: str) -> UserQueryClassification:
        memory_result = await self.classify_as_memory(text)
        question_result = await self.classify_as_query(text)
        if question_result.is_question:
            return UserQueryClassification.query(question_result.question)
        if memory_result.is_fact:
            return UserQueryClassification.memory(memory_result.fact)
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

    def classify_sync(self, text: str) -> UserQueryClassification:
        return asyncio.run(self.classify_input(text))

    def _heuristic_memory(self, text: str) -> FactClassification:
        lower = text.lower()
        truthy = any(trigger in lower for trigger in ("remember", "note that", "record", "i", "my"))
        time_tokens = ["yesterday", "today", "ago", "last", "monday", "am", "pm"]
        has_time = any(token in lower for token in time_tokens)
        is_question = text.endswith("?")
        is_fact = truthy and not is_question or has_time and not is_question
        return FactClassification(is_fact=is_fact, fact=text if is_fact else "")

    def _heuristic_query(self, text: str) -> QuestionClassification:
        lower = text.lower()
        contains_when = "when" in lower
        is_question = text.endswith("?")
        personal = any(pronoun in lower for pronoun in ("i", "my", "me"))
        if contains_when and is_question and personal:
            return QuestionClassification(is_question=True, question=text)
        return QuestionClassification(is_question=False, question="")

    def _build_prompt(self, instruction: str, text: str) -> str:
        return f"{instruction}\n------------\n{text}."

    async def _respond_with_model(self, prompt: str) -> str:
        if not self._session_factory:
            raise RuntimeError("No session factory registered for model calls")
        session = self._session_factory()
        response = await session.respond(prompt)
        if hasattr(response, "content"):
            return response.content
        return str(response)
