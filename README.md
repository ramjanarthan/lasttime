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
✨ Hands-free UX powered by Apple's latest SpeechRecognizer APIs <br>

### Why

This project is my sandbox for testing some core themes:
1. How does voice-first agentic UX look like?
2. How does agentic engineering help in product development?

My notes so far:
1. It's always been important to give the user some when your application is taking action, and this doesn't change with voice-based AI. This holds during the interaction phase where it is important to meaningful show that the agent is listening/paying attention, and the action phase to convey the agent is working on generating an 'answer'. However, since an agent could take a lot of actions, having an UI abstraction to show the user can help. In my case, I designed the 'action' indicator (the 5 bubbles) to allow me to do this in an intuitive way.
2. I wanted to deter long conversations for this app, so I modeled the UI around a translation app. There is only one input and output box whose contents get written over with every new inputs, communicating to the user that while generally AI is capable of longform conversations, this project doesn't support that. I wanted to focus solely on the use case of answering simple queries in this app, rather than sliding into full on assistant mode (there are already plenty of apps that do that).
3. I found agentic engineering to be a mixed bag. One thing that that worked well was using agents to improving prompt by allowing it to hill climb based on performance on an evaluation set. The coding agent came up with its own experiments (you can see them in https://github.com/ramjanarthan/lasttime/tree/main/prompt_experiments) which helped me get more ideas to play with the prompts to fine-tune the final setup.
4. Apple has already done a lot of work to squeeze performance out of the Foundation Models. To take advantage of that, using Swift's Generable types was very useful, since it provided structured outputs and improved correctness in one go. Make note, even the ordering of the properties in the struct can make a difference! (more great tips here: https://www.natashatherobot.com/p/swift-prompt-engineering-apples-foundationmodels)

### TODOs
1. Better handling of Foundation Model edge cases
2. Improve performance on query handling