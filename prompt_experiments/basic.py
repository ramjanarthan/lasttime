import apple_fm_sdk as fm
import asyncio

async def main():
    # Get the default system foundation model
    model = fm.SystemLanguageModel()

    # Check if the model is available
    is_available, reason = model.is_available()
    if is_available:
        # Create a session
        session = fm.LanguageModelSession()

        # Generate a response
        response = await session.respond("Hello, how are you?")
        print(f"Model response: {response}")
    else:
        print(f"Foundation Models not available: {reason}")

# Run async function
asyncio.run(main())