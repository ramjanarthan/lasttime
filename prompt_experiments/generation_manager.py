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
        use_heuristics_only: bool = True,
    ) -> None:
        self.memory_store = memory_store or MemoryStore()
        self.memory_prompt = DEFAULT_MEMORY_PROMPT
        self.query_prompt = DEFAULT_QUERY_PROMPT

    async def classify_as_memory(self, text: str) -> FactClassification:
        cleaned = text.strip()
        session = fm.LanguageModelSession(instructions=DEFAULT_MEMORY_SESSION_INSTRUCTIONS)
        prompt = self._build_prompt(self.memory_prompt, cleaned)
        await session.respond(prompt, generating: FactClassification)

    async def classify_as_query(self, text: str) -> QuestionClassification:
        cleaned = text.strip()
        session = fm.LanguageModelSession(instructions=DEFAULT_QUERY_SESSION_INSTRUCTIONS)
        prompt = self._build_prompt(self.query_prompt, cleaned)
        await session.respond(prompt, generating: QuestionClassification)

    async def classify_input(self, text: str) -> UserQueryClassification:
        memory_result = await self.classify_as_memory(text)
        heuristic_memory_classification = self._heuristic_memory(text)

        question_result = await self.classify_as_query(text)
        heuristic_question_classification = self._heuristic_query(text)

        if question_result.is_question or heuristic_question_classification.is_question:
            return UserQueryClassification.query(question_result.question)
        if memory_result.is_fact or heuristic_memory_classification.is_fact:
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
