# Snake Game in Assembly 🐍

This project is a Snake game written in Assembly language. The game logic is implemented in Assembly, while C++ handles the screen output and execution. To improve performance, key presses are processed directly in Assembly, and C++ is responsible only for updating the screen.

In the future, the game will feature a menu system, a scoring mechanism, and a leaderboard to save high scores. 🎮

## Description

The Snake game follows the classic concept where the player controls a snake on the screen. The snake grows each time it eats a fruit. The player's objective is to avoid crashing into walls or the snake's own body. 🚧

## Current Features:
- **Game Logic:** Implemented in Assembly. ⚡
- **Input Handling:** Key presses (Arrow keys or WASD) are processed directly in Assembly. ⌨️
- **Graphics Rendering:** C++ handles screen rendering and updating. 🖥️
- **Platform:** Windows x64. 💻
- **Compiler:** MASM for Assembly code and a C++ compiler for execution. 🛠️
- **Performance Optimization:** Assembly is used for both game logic and input handling, making the game faster. 🚀

## Project Files

- **Assambly_Game.cpp:** The C++ file responsible for launching the game and handling screen output. 🚀
- **game.asm:** The Assembly file that contains all the game logic, including snake movement, fruit generation, and collision detection. 🐍
- **x64/Release/Assambly_Game.exe:** A precompiled executable file that can be run directly to play the game without needing to compile the code yourself. 🎮

## Play

Run Assambly_Game.exe to play. 🎮

## How to Play

- Control the snake using the **WASD** on your keyboard.
- The objective is to eat as many fruits as possible while avoiding walls and the snake's body. 🍎
- The snake grows longer each time it eats a fruit, and the score increases. 📈
- A game over screen will appear if the snake collides with a wall or its own body. 💥

## Future Updates

The following features will be added in future updates:

- **Menu System:** A navigable menu where players can start a new game, view high scores, and adjust settings. 🖥️
- **Score System:** Track the number of fruits eaten and calculate a score, which will be displayed at the end of each game. 📊
- **Leaderboard:** Save the highest scores and display them in the menu for players to compete. 🏅
- **Game Over Screen:** After the game ends, players will see their final score and have options to play again or exit. 🛑

## Contributing

If you'd like to contribute to the project or suggest improvements, feel free to fork the repository and create a Pull Request. All contributions are welcome! 🤝

