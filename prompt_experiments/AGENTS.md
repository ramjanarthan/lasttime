# Auto Prompt improvement
- This folder is dedicated to iterating on the prompt tuning layer for a project that will use Apple's local foundation models `apple_fm_sdk` (macOS only). The prompts are used for an application that is helping users store and recall facts about their personal life, specifically related to questions related to 'When was the last time I did ...". 


## Project setup
- inputs.py : Contains all the prompts, instructions and the corresponding DataClasses used. You are allowed to heavily iterate the values of the Prompts and Istructions, and change the structure of the Guided generation datastructures (annotated with @fm.generable) to achieve better output. 
- generation_manager.py : Contains the logic for classification in GenerationManager class. You are allowed to modify any of the logic here, as long as you don't break Apple's foundation model calling convention
- dataset.json : Contains the evaluation dataset. You are NOT allowed to modify it, but you may read it
- evaluate.py : Contains code run your classification logic against the evaluation dataset. You are NOT allowed to modify it, but you can read it
- DO NOT remove any of these files in this folder, or parent folders

## Experimentation
- `prompt_experiments/dataset.json` is the shared dataset; every entry is `{"text": ..., "kind": ..., "canonical": ...}`. Keep the `kind` values limited to `memory`, `query`, or `invalid` so comparators stay simple.
- Run `python prompt_experiments/evaluate.py` to test the current prompts against `dataset.json`; it reports counts, accuracy, and prints any mismatches made.


## Experiment Loop
- Create a subfolder at the ```prompt_experiments``` directory, and make a local version of ```inputs.py``` and ```generation_manager.py```. If you are starting based of a previous successful experiment, copy from that sub folder. Otherwise, copy from the ```prompt_experiments``` directory
- Copy the ```dataset.json``` and ```evaluate.py``` files to the subfolder
- Make useful modifications on ```inputs.py``` and ```generation_manager.py``` in the subfolder
- Test by running the evaluation script  and save the evaluation results locally to a file ```results.txt```.
- If the results are an improvement, make a new sub-folder at the root level based on those files and iterate. If not, make a new sub-folder based on the versions of the files in the root directory. Inspect the results of the evaluation to understand where to improve.
- DO NOT delete experiment results folders after they are run. Keep them for reproducibility.

Timeout: Each experiment should take less than 1 minute total (+ a few seconds for startup and eval overhead). If a run exceeds 1 minutes, kill it and treat it as a failure (discard and revert).

Crashes: If a run crashes (OOM, or a bug, or etc.), use your judgment: If it's something dumb and easy to fix (e.g. a typo, a missing import), fix it and re-run. If the idea itself is fundamentally broken, just skip it, log "crash" as the status in the tsv, and move on.

STOP ONLY WHEN EVALUATION IS ABOVE 80%: Once the experiment loop has begun (after the initial setup), do NOT pause to ask the human if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The human might be asleep, or gone from a computer and expects you to continue working indefinitely until you are manually stopped. You are autonomous. If you run out of ideas, think harder — look up best prompt practices

## Apple's Foundation model usage reference
- Apple's Foundation model reference: https://apple.github.io/python-apple-fm-sdk/getting_started.html
- Guided generation lets you constrain the model’s output to follow specific structures, formats, or schemas. This ensures applications receive structured, predictable data. The @generable decorator transforms a Python class into a generable type equivalent to a Swift Generable. Only classes decorated with @generable can be used for guided generation in LanguageModelSession.respond(prompt, generating: ). Under the hood, @generable applies Python dataclasses to your decorated class, so your class must be compatible with dataclass features for the @generable decorator to work.
Example use case:

@fm.generable("Product review analysis")
class ProductReview:
    sentiment: str = fm.guide("Overall sentiment", anyOf=["positive", "negative", "neutral"])
    rating: float = fm.guide("Product rating", range=(1.0, 5.0))
    keywords: List[str] = fm.guide("Key features mentioned", count=3)

async def analyze_review():
    session = fm.LanguageModelSession(instructions="You are a product review analyzer.")

    result = await session.respond(
        "This laptop is amazing! Great performance and battery life.",
        generating=ProductReview
    )

    print(f"Sentiment: {result.sentiment}")  # for example, "positive"
    print(f"Rating: {result.rating}")        # for example, 4.5
    print(f"Keywords: {result.keywords}")    # for example, ["performance", "battery", "laptop"]



