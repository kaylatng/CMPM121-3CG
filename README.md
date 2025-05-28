# 3CG

CMPM 121 Assignment 3\
Name: Kayla Nguyen\
Game Title: _3CG_

## IMPLEMENTATION

### PROGRAMMING PATTERNS

COMMANDS\
I am using commands in the grabber.lua file to grab and release cards.

STATE\
I am managing the state of each card using state managers in card.lua.

FLYWEIGHT\
Flyweight is used for the card spritesheet to reduce the amount of files needed to render. I also applied Flyweight Patterns to my constants.lua file, which I reference in various files--these are constants that I use in multiple files, or multiple times and I do not want to change these values separately, or functions that I created to simplify the code in another file. I used this structure in various Javascript projects in CMPM 120, so this practice carried over to CMPM 121.

OBSERVER\
Observer is used in my update functions of each file, where they check for state changes or conditions to be true. In my grabber.lua file, it observers when the love game engine picks up a user's mouse click or release, and alerts a card object or stack if it is being picked up. This will change the state of the card object as the program observes the position of the mouse.

SEQUENCING\
I am also using sequencing patterns, specifically in the update method when I program the game to update and draw cards as the user interacts with the objects.

### FEEDBACK
Reviewer 1: Maddison Lobo -- Review partner for both discussion sections \
Comments: Merge conditions together and condense code where structures repeat. Remove code comments. I removed unecessary code segments and combined my conditional statements together when possible. \
Reviewer 2: Anna Truong \
Comments: Make stack "hitboxes" easier to reach for player. Clean up code comments. I fixed my stack hitboxes, so the program is able to detect when a player's cursor is hovering over a valid release position. I also added comments to annotate my code and removed most debug code comments, such as print statements or variable checking. \
Reviewer 3: Shayna Das \
Comments: Remove helper.lua and copy functions into respective classes. Add visuals instead of text to show foundation piles' suits. Originally wrote helper.lua to debug, but eventually realized I only used helper.lua to debug and not in the actual game. After doing this, I was able to lighten my program to less files. Added foundation pile images by drawing suits slightly enlarged.

### POSTMORTEM

A postmortem on where you assess the key pain points of your Solitaire project (the missing features and less than ideal code), how you planned on addressing them, and how successful those refactoring efforts were.

The main pain points of my code was repetitive functions or conditions. A cleaner implementation of my card piles could be made in the first iteration of my code. Additionally, my card "hitboxes" was an issue in my first implementation. I first cleaned up my repetitve functions and conditions by removing helper.lua, merging functions together (specifically in pile.lua), and merging conditions together. Some conditions did not work when I combined them, so I had to rearrange my code--most issues coming from flipping top cards face up--which required many edits to my code. In the end, I was able to successfully merge code fragments and maintain the functionality of my code. Another big issue was the acceptable areas to pick up and drop a card--this was fixed my enlarging the size of the pile's hitbox after a card is taken away and having the pile size become a fluctuating variable. The "pain points" of my project were fixable by editing conditions and modiying functions, which were not hard to do after revisiting my code and play testing it several times. 

### ASSETS

Sprites: Modified/scaled up spritesheet from https://emptysevenone.itch.io/playing-cards. All other sprites are made by me. \
Font: N/A \
Music: Jingle_Win_Synth_06.wav: https://freesound.org/people/LittleRobotSoundFactory/sounds/274181/ \
Misc: Code snippets from CMPM 121 live coding examples used. \
I didn’t make any of the assets in this project, unless explicitly mentioned.
