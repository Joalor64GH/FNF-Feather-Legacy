# Where are the files?

----------------

The files have been separated for better organization,
if you think navigating through the files is hard,
Press Ctrl+Shift+P (on Visual Studio Code) or Ctrl+P (on Sublime Text) to open up the File Viewer,
type in a file name and it shall take you there faster than the explorer

----------------

## Folder Structure

The folder structure goes as follows:

- `feather`
	- Contains various classes that are actively used by the main game, this is the place to go if you want to make your own changes to the base game
- `flixel`
	- Contains classes that override the game engine's default classes, this is often to fix bugs related to said classes
- `test`
	- This folder is likely tied to in-game tests, as the project is still in a development phase, this folder is expected to be here

## Subfolder Structure

- `feather`
	- `core`
		- The `core` folder contains many of the classes that have no real visual appearance
		and are instead used as backend files for the game to work with,
		such as `Controls`, `Highscore`, and `Utils`
		----------------
		- `data`
			- The `data` folder contains many of the classes that the game actively uses,
			if you wish to add/edit game settings or mess with the assets system,
			`APIs` and `Handlers` is for you
		----------------
		- `music`
			- The `music` folder contains classes that handle song playing and events during gameplay,
			along with chart parsing and loading
		----------------
		- `options`
			- The `options` folder contains a few objects to handle options,
			those having some level of visual look in-game, but still just being initializable objects
	- `gameObjs`
		- This is where all the files related to Game Objects are stored,
		if you wish to modify `Character`s or `Note`s,
		you may do so here, User Interface classes are also located there
		----------------
		- `shaders`
			- The `shaders` folder contains, well, Sprite Shaders,
			it is used by a few of the classes and can be later added into if needed
		----------------
		- `ui`
			- The `ui` folder stores the files user by the User Interface, for instance,
			the Game's User Interface (which shows Score Information, Health, etc...) is located there
	- `stage`
		- This is where game backgrounds, the so called "stages" are stored,
		this is used during gameplay and you can add into it to your own needs
		----------------
		- `parts`
			- The `parts` folder contains some objects that are used in some of the stages
		----------------
		- An useful bit of information about stages, is that the class that handles them is named `BaseStage`,
		so if you want to create your own custom stage,
		make sure to extend that class, which is also used as a template
	- `state`
		- Finally, `state` is the folder where all your Game States/Scenes are located,
		you can modify these files as you wish in order to get the result you wish to.
		----------------
		- `editors`
			- The `editors` folder contains all the visual in-game editors, such as the `ChartEditor` which is used for players to edit charts
		----------------
		- `menus`
			- The `menus` folder contains the in-game menus that can be accessed in a handful of ways,
			such as the `MainMenu`, the `FreeplayMenu`, and so on
		----------------
		- `subState`
			- As the name implies, the `subState` folder stores States that go on top of currently active ones,
			the so called SubStates (or SubScenes if you wanna call them that), the `PauseSubState` (Pause Menu) and `GameOverSubState` (Game Over Screen) are there if you wish to thinker with them
----------------