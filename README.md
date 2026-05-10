# Last Time

A macOS menu bar app to help you remember things. 
You can:
1. Note down things
2. Ask questions and get relevant answers (if possible!)  

### Demo

<img src="./demo.gif" alt="App Demo" width="600"/>

Full demo [here](https://github.com/ramjanarthan/lasttime/blob/main/lastTimeDemo.mp4)

### Features
✨ Completely on-device, your data never leaves your macbook <br>
✨ Powered by the latest and greatest of Apple's Foundation Models <br>

### Why

This project is my sandbox for testing some core themes:
1. How does voice-first agentic UX look like?
2. How does agentic engineering help in product development?

My notes so far:
1. It's always been important to give the user some feedback when an action is happening, and this doesn't change with voice-based AI. This is applicable both during the interaction phase (so it is important to meaningful show that the agent is listening/paying attention) and the action phase (to convey that some action has taken place). However, since agents can sometimes take a lot of actions, it may be important to have an abstraction over that to show the user. In my case, I designed the 'action' indicator (the 5 bubbles) to allow me to do both of this in low-effort way
2. I wanted to deter long conversations for this app, so I modeled the UI around a translation app. There is only one input and output box which get written over with newer inputs, communicating to the user that while AI is capable of longform conversations, this project isn't meant for that. The reason for this is I wanted to focus solely on the use case of answering simple queries and doing that really well, rather than sliding into full-on assistant mode (there are already plenty of apps that do that)
3. Agentic engineering is a mixed bag. One thing that I found that worked well was improving prompts, by allowing it to hill climb based on performance on an evaluation set. The coding agent came up with its own experiments (you can see them in https://github.com/ramjanarthan/lasttime/tree/main/prompt_experiments) which helped me get more ideas to play with the prompts.
4. Apple has already done a lot of work to squeeze out performance of the Foundation Models. To take advantage of that, using Swift's Generable types was very useful, since it provided structured outputs and improved correctness in one go. Make note, ordering of the properties in the struct can make a difference! (more great tips here: https://www.natashatherobot.com/p/swift-prompt-engineering-apples-foundationmodels)

### TODOs
1. Better handling of Foundation Model edge cases
2. Improve performance on query handling