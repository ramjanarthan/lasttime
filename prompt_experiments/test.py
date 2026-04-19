import apple_fm_sdk as fm
import asyncio

async def main():
    session = fm.LanguageModelSession()
    userInput = "Where did I go on 28th May 2024?"  # Example user input; replace with actual input as needed
    memory = "I went to the gym on 28th May 2024."
    prompt = "You are an assistant that helps the user remember things. The user has told you: " + memory + " . Now they ask you: " + userInput + " . Please generate a helpful response that answers the user's question based on the information they have given you. Be concise and accurate."
    return await session.respond(prompt)

async def be_nice():
    session = fm.LanguageModelSession()
    memory = "I went to the gym on 28th May 2024."
    prompt = "You are an assistant that helps the user remember things. The user has told you: " + memory + " . Generate a simple acknowledgment of noting this information. Be concise and polite. Don't provide any additional information or commentary."
    return await session.respond(prompt)

@fm.generable("Slot filling of a user input")
class Fact:
    who: str
    what: str
    when: str
    where: str

async def classify(input: str) -> Fact:
    session = fm.LanguageModelSession()
    userInput = input 
    prompt = "The user has given you a sentence: '" + userInput + "'. Please extract the following information if it is present: who is the subject of the sentence (who), what action or event is described (what), when did it happen (when), and where did it happen (where). If any of this information is not present in the sentence, return an empty string for that field. "
    return await session.respond(prompt, generating=Fact)

if __name__ == "__main__":
    # print(asyncio.run(classify("I went to the gym on 28th May 2024")))
    # print(asyncio.run(classify("I ate my lunch today")))
    # print(asyncio.run(classify("I had a meeting with Sarah yesterday at the cafe"))) 
    print(asyncio.run(be_nice()))