//
//  GameScene.m
//  nonogrammadness
//
//  Created by Nathan Demick on 8/31/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import "GameScene.h"
#import "LevelSelectScene.h"
#import "UpgradeScene.h"
#import "TitleScene.h"

#import "GameSingleton.h"
#import "SimpleAudioEngine.h"

#import "GameConfig.h"

#define kActionMark 1
#define kActionFill 2

#define kBlockEmpty 0
#define kBlockMarked 1
#define kBlockFilled 2

#define kActionLockNone 0
#define kActionLockMark 1
#define kActionLockEmpty 2

@implementation GameScene
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameScene *layer = [GameScene node];
	
	// add layer as a child to scene
	[scene addChild:layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
- (id)init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if ((self = [super init]))
	{
		// Make layer response to touch events
		[self setIsTouchEnabled:YES];
		
		// ask director the the window size
		CGSize windowSize = [CCDirector sharedDirector].winSize;
		
		// This string gets appended onto all image filenames based on whether the game is on iPad or not
		if ([GameSingleton sharedGameSingleton].isPad)
		{
			hdSuffix = @"-hd";
			fontMultiplier = 2;
			blockSize = 48;

			// UI items will have to be offset by this value for the iPad
			iPadOffset = ccp(64, 32);
			
			// The puzzle grid is this much offset from the left/bottom of the screen
			gridOffset = ccp(160, 100);
			gridOffset = ccpAdd(iPadOffset, gridOffset);
		}
		else
		{
			hdSuffix = @"";
			fontMultiplier = 1;
			blockSize = 24;
			
			iPadOffset = ccp(0, 0);
			
			// The puzzle grid is this much offset from the left/bottom of the screen
			gridOffset = ccp(80, 50);
		}
		
		// Initialize other game settings
		action = kActionMark;
		actionLock = kActionLockNone;
		hits = misses = 0;
		secondsLeft = 1800;		// 30 minutes
		paused = NO;
		
		// Create/add background
		CCSprite *bg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"background%@.png", hdSuffix]];
		bg.position = ccp(windowSize.width / 2, windowSize.height / 2);
		[self addChild:bg z:0];
		
		// Create/add action buttons
		markButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"mark-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"mark-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Set current action to "mark"
			action = kActionMark;
			
			// Set the button to be "active"
			[markButton selected];
			[fillButton unselected];
			
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
		}];
		
		// "Mark" button is active by default
		[markButton selected];
		
		fillButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"fill-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"fill-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Set current action to "mark"
			action = kActionFill;
			
			// Set the button to be "active"
			[markButton unselected];
			[fillButton selected];
			
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
		}];
		
		// Create the menu that houses the action buttons
		CCMenu *actionButtonsMenu = [CCMenu menuWithItems:fillButton, markButton, nil];
		[actionButtonsMenu alignItemsHorizontallyWithPadding:8];
		actionButtonsMenu.position = ccp(windowSize.width / 2, markButton.contentSize.height / 2 + iPadOffset.y + 3);	// 3 pixels off the bottom of the screen
		[self addChild:actionButtonsMenu z:2];
		
		// Puzzle grid background
		CCSprite *grid = [CCSprite spriteWithFile:[NSString stringWithFormat:@"grid-background%@.png", hdSuffix]];
		grid.position = ccp(windowSize.width / 2 + (2 * fontMultiplier), grid.contentSize.height / 2 + gridOffset.y - (4 * fontMultiplier));	// -4 to account for drop shadow
		[self addChild:grid z:1];
		
		// Create clue highlights
		horizontalClueHighlight = [CCSprite spriteWithFile:[NSString stringWithFormat:@"clue-highlight-horizontal%@.png", hdSuffix]];
		horizontalClueHighlight.opacity = 0;		// Make invisible
		[self addChild:horizontalClueHighlight z:2];

		verticalClueHighlight = [CCSprite spriteWithFile:[NSString stringWithFormat:@"clue-highlight-vertical%@.png", hdSuffix]];
		verticalClueHighlight.opacity = 0;		// Make invisible
		[self addChild:verticalClueHighlight z:2];
		
		// Create timer and % complete labels
		CCSprite *statusBackground = [CCSprite spriteWithFile:[NSString stringWithFormat:@"status-background%@.png", hdSuffix]];
		statusBackground.position = ccp(windowSize.width / 2, grid.position.y + grid.contentSize.height / 2 + statusBackground.contentSize.height / 2);	// position directly above grid
		[statusBackground.texture setAliasTexParameters];
		[self addChild:statusBackground z:1];
		
		timerLabel = [CCLabelBMFont labelWithString:@"30:00" fntFile:[NSString stringWithFormat:@"7px4bus-35%@.fnt", hdSuffix]];
		timerLabel.position = ccp(133 * fontMultiplier, 32 * fontMultiplier);
		
		[statusBackground addChild:timerLabel];
		
		percentCompleteLabel = [CCLabelBMFont labelWithString:@"00" fntFile:[NSString stringWithFormat:@"7px4bus-35%@.fnt", hdSuffix]];	// TODO: change this to size 42px
		percentCompleteLabel.position = ccp(267 * fontMultiplier, 66 * fontMultiplier);
		
		[statusBackground addChild:percentCompleteLabel];
		
		// Create pause button
		pauseButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"pause-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"pause-button-selected%@.png", hdSuffix] block:^(id sender) {
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			// Allow the pause button to be used to resume, as well as the "resume" button on the overlay
			if (paused)
			{
				[self unpause];
			}
			else
			{
				[self pause];
			}
		}];
		
		// Pause menu
		CCMenu *pauseMenu = [CCMenu menuWithItems:pauseButton, nil];
		pauseMenu.position = ccp((pauseButton.contentSize.width / 2) + (5 * fontMultiplier) + iPadOffset.x, grid.position.y + (grid.contentSize.height / 2) + (3 * fontMultiplier) + pauseButton.contentSize.height / 2);	// 5px off the left side
		[self addChild:pauseMenu z:1];
		
		// Level to load
		int currentLevel = [GameSingleton sharedGameSingleton].level;
		
		// Create arrays of levels & completion times
		levels = [[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Levels" ofType:@"plist"]] retain];
		levelTimes = [[NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"]] retain];
		
		NSDictionary *level;
		// If the selected level index is within bounds...
		if (currentLevel >= 0 && currentLevel < [levels count])
		{
			level = [levels objectAtIndex:currentLevel];
			isTutorial = NO;
		}
		// Otherwise, assume it's the tutorial
		else
		{
			level = [NSDictionary dictionaryWithObjectsAndKeys:@"Easy", @"difficulty", @"The letter 'G'", @"title", @"tutorial.tmx", @"filename", nil];
			isTutorial = YES;
			tutorialStep = 1;
						
			// Set up the "next" button that progresses thru tutorial steps
			tutorialButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"tutorial-next-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"tutorial-next-button-selected%@.png", hdSuffix] block:^(id sender) {
				// Play SFX
				[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
				
				[self dismissTextWindow];
				
				// Show tutorial text on steps that don't require action
				// i.e. the steps here all require the player to mark or fill certain rows/columns
				// The corresponding step increment code is in the update: method
				if (tutorialStep != 6 && 
					tutorialStep != 10 && 
					tutorialStep != 13 && tutorialStep != 14 && tutorialStep != 15 && tutorialStep != 17 && tutorialStep != 18 && tutorialStep != 19)
				{
					// Show current instructions
					[self showTutorial];
					
					// Increment counter
					tutorialStep++;
				}
				else
				{
					// Hide the button and set it to inactive
					tutorialButton.isEnabled = YES;
					tutorialButton.opacity = 255;
				}
			}];
			
			tutorialButton.opacity = 0;
			
			tutorialMenu = [CCMenu menuWithItems:tutorialButton, nil];
			tutorialMenu.position = ccp(windowSize.width - tutorialButton.contentSize.width / 1.5 - iPadOffset.x, windowSize.height / 2.5);
			[self addChild:tutorialMenu z:3];
			
			// Show current instructions + "next" button after a slight delay
			[self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:1.0], [CCCallBlock actionWithBlock:^(void) {
				[self showTutorial];
				
				[tutorialButton runAction:[CCFadeIn actionWithDuration:0.2]];
				
				// Increment counter
				tutorialStep++;
			}], nil]];
		}
		
		NSString *filename = [level objectForKey:@"filename"];
	
		// Load the .tmx file into memory
		[self loadPuzzleWithFile:filename];
		
		// Change the grid offset and add an overlay if it's a smaller puzzle
		if (gridSize < maxGridSize)
		{
			gridOffset = ccpAdd(gridOffset, ccp(0, (maxGridSize - gridSize) * blockSize));
			
			// Add an "overlay" on top of the grid background to grey out areas that can't be interacted with
			CCSprite *gridOverlay = [CCSprite spriteWithFile:[NSString stringWithFormat:@"grid-overlay%@.png", hdSuffix]];
			gridOverlay.position = ccp(windowSize.width / 2, grid.position.y + (2 * fontMultiplier));	// +2 to account for drop shadow
			[self addChild:gridOverlay z:2];
		}
		
		// Instantiate the array that holds whether each puzzle block is "marked", "filled", or blank
		gridStatus = [[NSMutableArray arrayWithCapacity:gridSize * gridSize] retain];
		
		// Instantiate the array that holds mark/fill sprites
		gridSprites = [[NSMutableArray arrayWithCapacity:gridSize * gridSize] retain];
		
		// By default, all the blocks are "empty"
		for (int i = 0, j = gridSize * gridSize; i < j; i++)
		{
			[gridStatus addObject:[NSNumber numberWithInt:kBlockEmpty]];
			[gridSprites addObject:[NSNull null]];
		}
		
		[self generateClues];
		
		// Set up pause overlay
		pauseOverlay = [CCSprite spriteWithFile:[NSString stringWithFormat:@"pause-overlay-background%@.png", hdSuffix]];
		pauseOverlay.position = ccp(-pauseOverlay.contentSize.width / 2, grid.position.y + (2 * fontMultiplier));	// +2 to account for drop shadow
		[self addChild:pauseOverlay z:6];
		
		CCMenuItemImage *resumeButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"resume-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"resume-button-selected%@.png", hdSuffix] block:^(id sender) {
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			[self unpause];
		}];
		
		CCMenuItemImage *quitButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"quit-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"quit-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Increment the "attempts" counter for this level, then return to the level select
			
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
			
			// Only save time data on "real" levels
			if (isTutorial == NO)
			{
				// Load level metadata dictionary
				int currentLevelIndex = [GameSingleton sharedGameSingleton].level;
				
				// Make mutable dictionary of current level times
				NSMutableDictionary *timeData = [NSMutableDictionary dictionaryWithDictionary:[levelTimes objectAtIndex:currentLevelIndex]];
				
				// Set local vars with the default/current values
				NSNumber *attempts = [[levelTimes objectAtIndex:currentLevelIndex] objectForKey:@"attempts"];
				
				// Increment attempts
				[timeData setValue:[NSNumber numberWithInt:[attempts intValue] + 1] forKey:@"attempts"];
				
				// Re-save
				[levelTimes replaceObjectAtIndex:currentLevelIndex withObject:timeData];
				[[NSUserDefaults standardUserDefaults] setObject:levelTimes forKey:@"levelTimes"];
			}
			
			if (isTutorial)
			{
				// Go back to the title scene
				CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[TitleScene node]];
				[[CCDirector sharedDirector] replaceScene:transition];
			}
			else
			{
				// Go back to the level select scene
				CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[LevelSelectScene node]];
				[[CCDirector sharedDirector] replaceScene:transition];
			}
		}];
		
		CCMenu *pauseOverlayMenu = [CCMenu menuWithItems:resumeButton, quitButton, nil];
		[pauseOverlayMenu alignItemsVerticallyWithPadding:11.0];
		pauseOverlayMenu.position = ccp(pauseOverlay.contentSize.width / 2, pauseOverlay.contentSize.height / 2);
		[pauseOverlay addChild:pauseOverlayMenu];
		
		// Play music
		if (isTutorial)
		{
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"tutorial.mp3"];
		}
		else
		{
			// Play random music track
			int trackNumber = (float)(arc4random() % 100) / 100 * 2 + 1;	// 1 - 3
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:[NSString stringWithFormat:@"%i.mp3", trackNumber]];
		}
		
		[self schedule:@selector(update:) interval:1.0];
	}
	return self;
}

/**
 * Update method. Counts down the timer, primarily. Also checks certain conditions in the tutorial
 */
- (void)update:(ccTime)dt
{
	secondsLeft--;
	
	if (secondsLeft < 0)
	{
		secondsLeft = 0;
		[self lose];
	}
	
	// Update timer label
	[timerLabel setString:[NSString stringWithFormat:@"%02i:%02i", secondsLeft / 60, secondsLeft % 60]];
	
	if (isTutorial)
	{
		switch (tutorialStep) 
		{
			case 6:
				{
					// Check whether the first column is filled
					BOOL success = YES;
					for (int i = 0; i < gridSize * gridSize; i += gridSize)
					{
						// If any one of the blocks isn't filled, the check fails
						if ([[gridStatus objectAtIndex:i] intValue] != kBlockFilled)
						{
							success = NO;
						}
					}
					
					// However, if the check passes, go to the next step
					if (success)
					{
						// Show instructional text
						[self showTutorial];
						
						// Increment step counter
						tutorialStep++;
						
						// Enable/show button
						tutorialButton.isEnabled = YES;
						tutorialButton.opacity = 255;
					}
				}
				break;
			
			case 10:
				{
					// Check whether the third column is correctly filled
					BOOL success = YES;
					for (int i = 2; i < gridSize * gridSize; i += gridSize * 2)
					{
						// If any one of the blocks isn't filled, the check fails
						if ([[gridStatus objectAtIndex:i] intValue] != kBlockFilled)
						{
							success = NO;
						}
					}
					
					// However, if the check passes, go to the next step
					if (success)
					{
						// Show instructional text
						[self showTutorial];
						
						// Increment step counter
						tutorialStep++;
						
						// Enable/show button
						tutorialButton.isEnabled = YES;
						tutorialButton.opacity = 255;
					}
				}
				break;
			
			case 13:
				{
					// Check whether the other squares in the third column are all marked
					BOOL success = YES;
					for (int i = 2; i < gridSize * gridSize; i += gridSize)
					{
						// If any one of the blocks is empty, the check fails
						if ([[gridStatus objectAtIndex:i] intValue] == kBlockEmpty)
						{
							success = NO;
						}
					}
					
					// However, if the check passes, go to the next step
					if (success)
					{
						// Show instructional text
						[self showTutorial];
						
						// Increment step counter
						tutorialStep++;
					}
				}
				break;
			case 14:
				{
					// Check whether fourth column is correctly filled
					int count = 0;
					for (int i = 3; i < gridSize * gridSize; i += gridSize)
					{
						// If any one of the blocks is empty, the check fails
						if ([[gridStatus objectAtIndex:i] intValue] == kBlockFilled)
						{
							count++;
						}
					}
					
					// However, if the check passes, go to the next step
					if (count == 4)
					{
						// Show instructional text
						[self showTutorial];
						
						// Increment step counter
						tutorialStep++;
					}
				}
				break;
			case 15:
				{
					// Check whether the fifth column is all marked
					BOOL success = YES;
					for (int i = 4; i < gridSize * gridSize; i += gridSize)
					{
						// If any one of the blocks is empty, the check fails
						if ([[gridStatus objectAtIndex:i] intValue] != kBlockMarked)
						{
							success = NO;
						}
					}
					
					// However, if the check passes, go to the next step
					if (success)
					{
						// Show instructional text
						[self showTutorial];
						
						// Increment step counter
						tutorialStep++;
						
						// Enable/show button
						tutorialButton.isEnabled = YES;
						tutorialButton.opacity = 255;
					}
				}
				break;
			case 17:
				{
					// Check whether the first row is filled
					BOOL success = YES;
					for (int i = 4 * gridSize; i < gridSize * gridSize; i++)
					{
						// If any one of the blocks is empty, the check fails
						if ([[gridStatus objectAtIndex:i] intValue] == kBlockEmpty)
						{
							success = NO;
						}
					}
					
					// However, if the check passes, go to the next step
					if (success)
					{
						// Show instructional text
						[self showTutorial];
						
						// Increment step counter
						tutorialStep++;
					}
				}
				break;
			case 18:
				{
					// Check whether the second, third, and fourth rows are all non-empty
					BOOL success = YES;
					for (int i = 1 * gridSize; i < 4 * gridSize; i++)
					{
						// If any one of the blocks is empty, the check fails
						if ([[gridStatus objectAtIndex:i] intValue] == kBlockEmpty)
						{
							success = NO;
						}
					}
					
					// However, if the check passes, go to the next step
					if (success)
					{
						// Show instructional text
						[self showTutorial];
						
						// Increment step counter
						tutorialStep++;
					}
				}
				break;
			default:
				break;
		}
	}
}

/**
 * Progresses through the steps in the tutorial
 */
- (void)showTutorial
{
	// ask director the the window size
	CGSize windowSize = [CCDirector sharedDirector].winSize;
	
	NSArray *instructions = [NSArray arrayWithObjects:@"Welcome to Nonogram Madness! Nonograms are logic puzzles that reveal an image when solved.", 
			/* 2 */			@"Solve each puzzle using the numeric clues on the top and left of the grid.",
			/* 3 */			@"Each number represents squares in the grid that are \"filled\" in a row or column.",
			/* 4 */			@"Clues with multiple numbers mean a gap of one (or more) between filled squares.",
			/* 5 */			@"Look at the first column. The clue is \"5\". Tap \"fill\" then tap all 5 squares.",
							// Action
			/* 6 */			@"The second column is harder. We don't know where the two single filled squares are.",
			/* 7 */			@"Skip difficult rows or columns and come back to them later.",
			/* 8 */			@"Look at the third column. The clue is \"1 1 1\". There's a gap between each filled square.",
			/* 9 */			@"Make sure the \"fill\" button is selected, then fill in three squares with a gap between each.",
							// Action
			/* 10 */		@"You can use the \"mark\" action to protect blocks that are supposed to be empty.",
			/* 11 */		@"Erase a marked square by tapping it again. Don't worry about making a mistake.",
			/* 12 */		@"Tap \"mark\" and mark the empty squares so you don't accidentally try to fill them in later.",
							// Action
			/* 13 */		@"Check out the fourth column. The clue is \"1 3\". Fill one square, leave a gap, then fill three more.",
							// Action
			/* 14 */		@"The fifth column is empty. \"Mark\" all those squares to show they don't need to be filled in.",
							// Action
			/* 15 */		@"Let's move on to clues in the rows. The first row has four sequential filled squares.",
			/* 16 */		@"Fill in the only open square in this row to complete it.",
							// Action
			/* 17 */		@"The second, third, and fourth rows are already complete. Mark all the open squares in them.",
							// Action
			/* 18 */		@"Use what you've learned so far to finish the puzzle. I'm sure you can figure it out.",
							// Action
							 nil];	
	
	// Show the instructional text for the current step
	if (tutorialStep - 1 < [instructions count])
	{
		[self showTextWindowAt:ccp(windowSize.width / 2, (110 * fontMultiplier) + iPadOffset.y) withText:[instructions objectAtIndex:tutorialStep - 1]];
	}
	
//	CCLOG(@"Step %i", tutorialStep);
	
	// Determine if any additional graphics or effects need to be shown
	switch (tutorialStep) 
	{
		case 1:
			break;
		case 2:
			// Blink over clue areas
			tutorialHighlight = [CCSprite spriteWithFile:[NSString stringWithFormat:@"2%@.png", hdSuffix]];
			tutorialHighlight.position = ccp(100 * fontMultiplier + iPadOffset.x, 269 * fontMultiplier + iPadOffset.y);
			[self addChild:tutorialHighlight z:1];
			break;
		case 3:
			break;
		case 4:
			// Hide clue highlihgt
			tutorialHighlight.opacity = 0;
			break;
		case 5:
			// Highlight first column blocks
			[tutorialHighlight setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"5%@.png", hdSuffix]]];
			tutorialHighlight.opacity = 255;
			
			// Hide the button and set it to inactive
			tutorialButton.opacity = 0;
			[tutorialButton setIsEnabled:NO];
			break;
		case 6:
			// Highlight second column clues
			[tutorialHighlight setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"6%@.png", hdSuffix]]];
			break;
		case 7:
			// Highlight second column clues
			break;
		case 8:
			// Hightlight third column clues

			[tutorialHighlight setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"8%@.png", hdSuffix]]];
			break;
		case 9:
			// Highlight correct third column blocks
			[tutorialHighlight setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"9%@.png", hdSuffix]]];
			tutorialHighlight.opacity = 255;
			
			// Hide the button and set it to inactive
			tutorialButton.opacity = 0;
			[tutorialButton setIsEnabled:NO];
			break;
		case 10:
			break;
		case 11:
			break;
		case 12:
			// Blink on correct fourth column blocks
			[tutorialHighlight setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"12%@.png", hdSuffix]]];
			
			// Hide the button and set it to inactive
			tutorialButton.opacity = 0;
			[tutorialButton setIsEnabled:NO];
			break;
		case 13:
			// Hide the button and set it to inactive
			tutorialButton.opacity = 0;
			[tutorialButton setIsEnabled:NO];
			
			// Highlight open blocks in fourth column
			[tutorialHighlight setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"13%@.png", hdSuffix]]];
			break;
		case 14:
			// Hide the button and set it to inactive
			tutorialButton.opacity = 0;
			[tutorialButton setIsEnabled:NO];
			
			// Highlight all open blocks in fifth column
			[tutorialHighlight setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"14%@.png", hdSuffix]]];
			break;
		case 15:
			[tutorialHighlight setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"15%@.png", hdSuffix]]];
			// Hide the button and set it to inactive
			tutorialButton.opacity = 0;
			[tutorialButton setIsEnabled:NO];
			break;
		case 16:
			// Blink over open square in first row
			tutorialHighlight.opacity = 255;
			[tutorialHighlight setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"16%@.png", hdSuffix]]];
			
			tutorialButton.opacity = 0;
			[tutorialButton setIsEnabled:NO];
			break;
		case 17:
			// Blink over 2nd, 3rd, and 4th rows
			[tutorialHighlight setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"17%@.png", hdSuffix]]];
			
			tutorialButton.opacity = 0;
			[tutorialButton setIsEnabled:NO];
			break;
		case 18:
			// Turn off highlights
			tutorialHighlight.opacity = 0;
			
			tutorialButton.opacity = 0;
			[tutorialButton setIsEnabled:NO];
			break;
		default:
			break;
	}
}

/**
 * Store the starting location of a player touch, and execute an action if the touched grid space is empty
 */
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];

	touchStart = touchPrevious = touchPoint;
	
	// Reset the "locked" row/column values
	lockedRow = lockedCol = -1;
	
	// Figure out the row/column that was touched
	touchRow = (touchPoint.y - gridOffset.y) / blockSize;
	touchCol = (touchPoint.x - gridOffset.x) / blockSize;
		
	// Only register the touch as "valid" if it's within the allowed indices of the grid
	if (touchRow < gridSize && touchRow >= 0 && touchCol < gridSize && touchCol >= 0)
	{
		// Show clue "highlights" in the correct position
		horizontalClueHighlight.opacity = 255;
		verticalClueHighlight.opacity = 255;
		
		verticalClueHighlight.position = ccp(iPadOffset.x + (80 * fontMultiplier) + (touchCol * blockSize) + verticalClueHighlight.contentSize.width / 2, iPadOffset.y + (410 * fontMultiplier) - verticalClueHighlight.contentSize.height - (2 * fontMultiplier));	// -2y for grid shadow
		horizontalClueHighlight.position = ccp(iPadOffset.x + horizontalClueHighlight.contentSize.width / 2 + (1 * fontMultiplier), gridOffset.y + (touchRow * blockSize) + horizontalClueHighlight.contentSize.height / 2);	// +1x for grid outline
		
		[self actionOnRow:touchRow andCol:touchCol];
	}
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
	
	// Store previous values, to determine if player moved his/her finger
	previousRow = touchRow;
	previousCol = touchCol;
	
	// Figure out the row/column that was touched
	touchRow = (touchPoint.y - gridOffset.y) / blockSize;
	touchCol = (touchPoint.x - gridOffset.x) / blockSize;

	// If player has moved finger and "locked" into a column, enforce
	if (lockedCol != -1)
	{
		touchCol = lockedCol;
	}
	if (lockedRow != -1)
	{
		touchRow = lockedRow;
	}
	
	// Only register the touch as "valid" if it's within the allowed indices of the grid
	if (touchRow < gridSize && touchRow >= 0 && touchCol < gridSize && touchCol >= 0)
	{
		// Lock into a row or column - iPhone/iPod Touch only
		if (lockedRow == -1 && lockedCol == -1 && ![GameSingleton sharedGameSingleton].isPad)
		{
			// Changed rows, which means moving up or down - lock into the current column
			if (previousRow != touchRow)
			{
				lockedCol = touchCol;
			}
			// Changed columns, which means moving left or right - lock into the current row
			else if (previousCol != touchCol)
			{
				lockedRow = touchRow;
			}
		}
		
		// Try to mark or fill only if the currently touched row/col is different from the previous row/col
		if (touchRow != previousRow || touchCol != previousCol)
		{
			// Update position of clue "highlights"
			CGPoint newVerticalPosition = ccp(iPadOffset.x + (80 * fontMultiplier) + (touchCol * blockSize) + verticalClueHighlight.contentSize.width / 2, iPadOffset.y + (410 * fontMultiplier) - verticalClueHighlight.contentSize.height - (2 * fontMultiplier));	// -2y for grid shadow
			CGPoint newHorizontalPosition = ccp(iPadOffset.x + horizontalClueHighlight.contentSize.width / 2 + (1 * fontMultiplier), gridOffset.y + (touchRow * blockSize) + horizontalClueHighlight.contentSize.height / 2);	// +1x for grid outline
			
			[verticalClueHighlight runAction:[CCMoveTo actionWithDuration:0.05 position:newVerticalPosition]];
			[horizontalClueHighlight runAction:[CCMoveTo actionWithDuration:0.05 position:newHorizontalPosition]];
											  
			// Try to mark or fill
			[self actionOnRow:touchRow andCol:touchCol];
		}
	}
	
	// "Reset" the previous touch point
	touchPrevious = touchPoint;
}

/**
 * Remove the "action lock"
 */
- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Reset the "action lock" (which prevents accidental toggling of marked blocks)
	actionLock = kActionLockNone;
	
	// Hide clue "highlights"
	horizontalClueHighlight.opacity = 0;
	verticalClueHighlight.opacity = 0;
}

/**
 * Loads the .tmx file and converts it to a "sane" NSArray structure. 
 * Also creates random levels if .tmx filename has the word "random" in it.
 */
- (void)loadPuzzleWithFile:(NSString *)filename
{
	// Load tile map for this particular puzzle
	CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:filename];
	CCTMXLayer *puzzleLayer = [tileMap layerNamed:@"Layer 1"];
	
	// Get details regarding how large the level is (e.g. 10x10 or 5x5)
	gridSize = tileMap.mapSize.width;
	
	// Largest possible puzzle size
	maxGridSize = 10;
	
	// Create a new data structure and contains the correct puzzle answers and un-inverts the y-axis
	puzzleAnswers = [[NSMutableArray arrayWithCapacity:gridSize * gridSize] retain];
	
	// If .tmx filename contains string "random", create a random puzzle
	if ([filename rangeOfString:@"random"].location != NSNotFound)
	{
		// Random percentage of filled blocks that will be put in the puzzle
		int fillPercentage;
		if ([filename rangeOfString:@"easy"].location != NSNotFound)
		{
			fillPercentage = 68;
		}
		else if ([filename rangeOfString:@"medium"].location != NSNotFound)
		{
			fillPercentage = 62;
		}
		else if ([filename rangeOfString:@"hard"].location != NSNotFound)
		{
			fillPercentage = 55;
		}
		
		for (int i = 0, j = gridSize * gridSize; i < j; i++)
		{
			// If a random number between 0 - 99 is lower than fill percentage, make the block "filled"
			if (arc4random() % 100 <= fillPercentage)
			{
				[puzzleAnswers addObject:[NSNumber numberWithInt:kBlockFilled]];
			}
			else
			{
				[puzzleAnswers addObject:[NSNumber numberWithInt:kBlockEmpty]];
			}
		}
	}
	else
	{
		// Translate the tilemap layer to a regular, non-y-axis inverted data structure
		for (int i = 0, j = gridSize * gridSize; i < j; i++)
		{
			int x = i % gridSize;
			int y = floor(i / gridSize);
			
			if ([puzzleLayer tileGIDAt:ccp(x, (gridSize - 1) - y)])
			{
				[puzzleAnswers addObject:[NSNumber numberWithInt:kBlockFilled]];
			}
			else
			{
				[puzzleAnswers addObject:[NSNumber numberWithInt:kBlockEmpty]];
			}
		}
	}
}

/**
 * Tries to either mark or fill a space in the puzzle grid, based on the player's currently selected "action"
 */
- (void)actionOnRow:(int)row andCol:(int)col
{
	// Get correct array index based on the selected row/col
	int index = row * gridSize + col;

	// Determine whether the block is empty, filled, or marked
	int status = [(NSNumber *)[gridStatus objectAtIndex:index] intValue];
	
	// Determine whether the move is valid or not
	BOOL validBlock = [[puzzleAnswers objectAtIndex:index] intValue] == kBlockFilled;
	
	// Proceed based on player's currently selected "action"
	if (action == kActionFill)
	{
		// Fill block if empty and it's a valid block
		if (validBlock && status == kBlockEmpty)
		{
			// Position the sprite at the touched row/col multiplied by the block size, then add the offset 
			// (since the grid isn't at [0,0]) and the sprite offset (since the anchor point is in the middle of the sprite)
			CCSprite *s = [CCSprite spriteWithFile:[NSString stringWithFormat:@"filled-square%@.png", hdSuffix]];
			s.position = ccp((col * blockSize) + gridOffset.x + blockSize / 2, (row * blockSize) + gridOffset.y + blockSize / 2);
			[self addChild:s z:2];
			
			// Add to reference array
			[gridSprites replaceObjectAtIndex:index withObject:s];
			
			// Update status array
			[gridStatus replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:kBlockFilled]];
			
			// Show particle effect
			[self createParticlesAt:s.position];
			
			// Increment # correct counter
			hits++;

			// check clues to see if they can be dimmed
			[self checkCompletedCluesForRow:row andCol:col];
			
			// Update "% complete" number
			[percentCompleteLabel setString:[NSString stringWithFormat:@"%02d", (int)(((float)hits / (float)totalHits) * 100.0)]];
			
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"hit.caf"];
			
			// Draw "preview" minimap - these sprites don't have to be referenced later
			[self drawMinimapAt:ccp((43 * fontMultiplier) + iPadOffset.x, (333 * fontMultiplier) + iPadOffset.y) 
					  withBlock:ccp(row, col)
						 onNode:self];
			
			if (hits == totalHits)
			{
				[self win];
			}
		}
		// Square is empty, but it's not a valid move
		else if (status == kBlockEmpty)
		{
			[[SimpleAudioEngine sharedEngine] playEffect:@"miss.caf"];
			
			// Run "shake" action
			CCShakyTiles3D *shaky = [CCShakyTiles3D actionWithRange:5 shakeZ:NO grid:ccg(5, 5) duration:0.2];
			[self runAction:[CCSequence actions:shaky, [CCStopGrid action], nil]];
			
			// Increment number of wrong guesses
			misses++;
			
			// Only remove time if not in the tutorial
			if (isTutorial == NO)
			{
				// Determine how much time to subtract
				if (misses == 1)
				{
					secondsLeft -= 120;	// 2 minutes
					
					// Create the label at the same position where the block sprite would be created
					[self createStatusMessageAt:ccp((col * blockSize) + gridOffset.x + blockSize / 2, (row * blockSize) + gridOffset.y + blockSize / 2) 
									   withText:@"-2 minutes"];
				} 
				else if (misses == 2)
				{
					secondsLeft -= 240;	// 4 minutes
					
					// Create the label at the same position where the block sprite would be created
					[self createStatusMessageAt:ccp((col * blockSize) + gridOffset.x + blockSize / 2, (row * blockSize) + gridOffset.y + blockSize / 2) 
									   withText:@"-4 minutes"];
				}
				else
				{
					secondsLeft -= 480;	// 8 minutes
					
					// Create the label at the same position where the block sprite would be created
					[self createStatusMessageAt:ccp((col * blockSize) + gridOffset.x + blockSize / 2, (row * blockSize) + gridOffset.y + blockSize / 2) 
									   withText:@"-8 minutes"];
				}
				
				// Update timer label immediately
				[timerLabel setString:[NSString stringWithFormat:@"%02i:%02i", secondsLeft / 60, secondsLeft % 60]];	
			}	// End if (isTutorial == NO)
		}
		// Otherwise, it's already filled, so play the "erk!" noise
		else
		{
			[[SimpleAudioEngine sharedEngine] playEffect:@"dud.caf"];			
		}
	}
	else if (action == kActionMark)
	{
		// Mark if the block is empty
		if (status == kBlockEmpty && actionLock != kActionLockEmpty)
		{
			// If the player keeps moving his finger around, only "mark" blocks, don't unmark them
			actionLock = kActionLockMark;
			
			// Create new sprite, add to layer
			CCSprite *s = [CCSprite spriteWithFile:[NSString stringWithFormat:@"marked-square%@.png", hdSuffix]];
			s.position = ccp((col * blockSize) + gridOffset.x + blockSize / 2, (row * blockSize) + gridOffset.y + blockSize / 2);
			[s.texture setAliasTexParameters];	// Attempt to alias for greater legibility
			[self addChild:s z:2];
			
			// Add to reference array
			[gridSprites replaceObjectAtIndex:index withObject:s];
			
			// Update status array
			[gridStatus replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:kBlockMarked]];
			
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"mark.caf"];
			
			// Show particle effect
			[self createParticlesAt:s.position];
		}
		// Remove mark if the block is already marked
		else if (status == kBlockMarked && actionLock != kActionLockMark)
		{
			// If the player keeps moving her finger around, only "unmark" blocks, don't mark them
			actionLock = kActionLockEmpty;
			
			// Remove from layer
			CCSprite *s = [gridSprites objectAtIndex:index];
			[self removeChild:s cleanup:YES];
			
			// Remove from reference array
			[gridSprites replaceObjectAtIndex:index withObject:[NSNull null]];
			
			// Update status array
			[gridStatus replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:kBlockEmpty]];
			
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"mark.caf"];
		}
		// Play a "erk!" SFX if block is filled
		else
		{
			[[SimpleAudioEngine sharedEngine] playEffect:@"dud.caf"];
		}
	}
}

- (void)generateClues
{
	// Create "clue" labels for this puzzle
	horizontalClues = [[NSMutableArray arrayWithCapacity:gridSize] retain];
	verticalClues = [[NSMutableArray arrayWithCapacity:gridSize] retain];
	
	// Parse puzzle data to generate the text that goes in each clue label
	totalHits = 0;
	int counterHoriz = 0;
	int counterVert = 0;
	BOOL previousHoriz = NO;
	BOOL previousVert = NO;
	NSString *textHoriz;
	NSString *textVert;
	
	for (int i = 0; i < gridSize; i++)
	{
		// Reset the "clue" strings each iteration
		textHoriz = @"";
		textVert = @"";
		
		for (int j = gridSize - 1; j >= 0; j--)
		{			
			// Check for vertial clues (columns)
			if ([[puzzleAnswers objectAtIndex:j * gridSize + i] intValue] == kBlockFilled)
			{
				counterVert++;
				previousVert = YES;
			}
			else if (previousVert == YES)
			{
				textVert = [textVert stringByAppendingFormat:@"%i\n", counterVert];
				counterVert = 0;
				previousVert = NO;
			}
		}
		
		for (int j = 0; j < gridSize; j++)
		{
			// Check for horizontal clues (rows)
			if ([[puzzleAnswers objectAtIndex:i * gridSize + j] intValue] == kBlockFilled)
			{
				counterHoriz++;
				previousHoriz = YES;
			}
			else if (previousHoriz == YES)
			{
				textHoriz = [textHoriz stringByAppendingFormat:@"%i ", counterHoriz];
				previousHoriz = NO;
				
				totalHits += counterHoriz;		// Used for "win" condition; only need to count on one side, since clues are counted twice
				counterHoriz = 0;
			}
		}
		
		// Conditional that checks if a row ends with filled blocks
		if (previousHoriz == YES)
		{
			textHoriz = [textHoriz stringByAppendingFormat:@"%i ", counterHoriz];
			previousHoriz = NO;
			
			totalHits += counterHoriz;
			counterHoriz = 0;
		}
		
		// Conditional that checks if a row ends with filled blocks
		if (previousVert == YES)
		{
			textVert = [textVert stringByAppendingFormat:@"%i\n", counterVert];
			counterVert = 0;
			previousVert = NO;
		}
		
		int defaultFontSize = 16;
		if ([textHoriz length] == 10)
		{
			// Create the label with a smaller font
			defaultFontSize = 14;
		}
		
		// Create horizontal clue label
		CCLabelTTF *horizontalClue = [CCLabelTTF labelWithString:@"0 " 
													  dimensions:CGSizeMake(160 * fontMultiplier, 24 * fontMultiplier) 
													   alignment:UITextAlignmentRight 
														fontName:@"slkscr.ttf" 
														fontSize:defaultFontSize * fontMultiplier];
		horizontalClue.position = ccp(iPadOffset.x, (blockSize * i) + ((maxGridSize - gridSize) * blockSize) + (50 * fontMultiplier) + horizontalClue.contentSize.height / 3 + iPadOffset.y);
		horizontalClue.color = ccc3(0, 0, 0);
		[horizontalClue.texture setAliasTexParameters];	// Try to alias the font for better legibility
		[self addChild:horizontalClue z:3];
		[horizontalClues addObject:horizontalClue];
		
		// Add the clue strings to each label
		if ([textHoriz length] > 0)
		{
			// Change the label
			horizontalClue.string = textHoriz;
			
			// Move up slightly if 5 clues
			if (defaultFontSize == 14)
			{
				horizontalClue.position = ccp(horizontalClue.position.x, horizontalClue.position.y - (1 * fontMultiplier));
			}
		}
		else 
		{
			// Set the text color as lighter since it's a zero - column already completed
			horizontalClue.color = ccc3(100, 100, 100);
		}

		defaultFontSize = 16;
		if ([textVert length] == 10)
		{
			defaultFontSize = 14;
		}
		
		// Create vertical clue label
		CCLabelTTF *verticalClue = [CCLabelTTF labelWithString:@"0\n" 
													dimensions:CGSizeMake(24 * fontMultiplier, 80 * fontMultiplier) 
													 alignment:UITextAlignmentCenter 
													  fontName:@"slkscr.ttf" 
													  fontSize:defaultFontSize * fontMultiplier];
		verticalClue.position = ccp((blockSize * i) + iPadOffset.x + (80 * fontMultiplier) + verticalClue.contentSize.width / 2, (270 * fontMultiplier) + iPadOffset.y);
		verticalClue.color = ccc3(0, 0, 0);
		[verticalClue.texture setAliasTexParameters];	// Try to alias the font for better legibility
		[self addChild:verticalClue z:3];
		[verticalClues addObject:verticalClue];
		
		if ([textVert length] > 0)
		{
			verticalClue.string = textVert;
			
			// Count the number of vertical clues, so we can offset the vertical position of hte label
			int verticalOffset = [[textVert componentsSeparatedByString:@"\n"] count] - 2;	// Default positioning is for 1 clue, and there's an extra \n on each string, so subtract 2 to make up for it
			float fontOffset = defaultFontSize + 1;
			if (defaultFontSize == 14)
			{
				fontOffset -= 0.5;
			}
			
			verticalClue.position = ccp(verticalClue.position.x, verticalClue.position.y + (verticalOffset * fontOffset * fontMultiplier));	// Font size is 16px, 17 is an approximation I guess?
		}
		else
		{
			// Set the text color as lighter since it's a zero - column already completed
			verticalClue.color = ccc3(100, 100, 100);
		}
	}	// End clue generator
}

/**
 * Cycle through a row/column to see if all the blocks have been filled in; if so, grey out (or "dim") the row/column clues
 */
- (void)checkCompletedCluesForRow:(int)row andCol:(int)col
{
	int columnTotal = 0;
	int filledColumnTotal = 0;
	
	int rowTotal = 0;
	int filledRowTotal = 0;

	for (int i = 0; i < gridSize; i++) 
	{
		int colIndices = i * gridSize + col;
		int rowIndicies = row * gridSize + i;
		
		// Get number of player filled blocks in this column
		if ([[gridStatus objectAtIndex:colIndices] intValue] == kBlockFilled)
		{
			filledColumnTotal++;
		}
		
		// Get total number of possible filled blocks for this column
		if ([[puzzleAnswers objectAtIndex:colIndices] intValue] == kBlockFilled)
		{
			columnTotal++;
		}
		
		// Get number of player filled blocks in this row
		if ([[gridStatus objectAtIndex:rowIndicies] intValue] == kBlockFilled)
		{
			filledRowTotal++;
		}
		
		// Get total number of possible filled blocks for this row
		if ([[puzzleAnswers objectAtIndex:rowIndicies] intValue] == kBlockFilled)
		{
			rowTotal++;
		}
	}

	// If player has filled all blocks in the column, change the color of the clue label
	if (columnTotal == filledColumnTotal)
	{
		[(CCLabelTTF *)[verticalClues objectAtIndex:col] setColor:ccc3(100, 100, 100)];
	}
	
	// If player has filled all blocks in the row, change the color of the clue label
	if (rowTotal == filledRowTotal)
	{
		[(CCLabelTTF *)[horizontalClues objectAtIndex:row] setColor:ccc3(100, 100, 100)];
	}
}

/**
 * Draws a pixel of the puzzle preview around a center point. To draw the whole thing, loop through the puzzle data array.
 */
- (void)drawMinimapAt:(CGPoint)position withBlock:(CGPoint)block onNode:(CCNode *)node
{
	int row = block.x;
	int col = block.y;
	
	// Create sprite
	CCSprite *b = [CCSprite spriteWithFile:[NSString stringWithFormat:@"preview-pixel%@.png", hdSuffix]];
	
	// Alias texture
	[[b texture] setAliasTexParameters];
	
	// Positions at 0, 0
	b.position = ccp((col * b.contentSize.width), (row * b.contentSize.height));
	
	// Determine total width of puzzle to place minimap anchor in center
	int minimapSize = gridSize * b.contentSize.width;
	
	// Offset the map so anchor is in center
	b.position = ccpSub(b.position, ccp(minimapSize / 2, minimapSize / 2));
	
	// Add the position argument for final placement
	b.position = ccpAdd(b.position, position);
	
	[node addChild:b z:2];
}

/**
 * Actions to take when player has won a puzzle
 */
- (void)win
{
	// ask director the the window size
	CGSize windowSize = [CCDirector sharedDirector].winSize;
	
	// Stop the timer countdown
	[self unschedule:@selector(update:)];
	
	// Prevent additional touch events from occurring
	[self setIsTouchEnabled:NO];
	
	// disable the pause button
	[pauseButton setIsEnabled:NO];
	
	// Dismiss the tutorial text window if it's open
	if (textWindowBackground.opacity > 0)
	{
		[self dismissTextWindow];
	}
	
	// Play "win" music
	[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"win.mp3" loop:NO];
	
	// Get current level index
	int currentLevelIndex = [GameSingleton sharedGameSingleton].level;
	
	// Hide clue "highlights"
	[horizontalClueHighlight runAction:[CCFadeOut actionWithDuration:0.1]];
	[verticalClueHighlight runAction:[CCFadeOut actionWithDuration:0.1]];
	
	CCSprite *overlay = [CCSprite spriteWithFile:[NSString stringWithFormat:@"win-overlay-background%@.png", hdSuffix]];
	overlay.position = ccp(windowSize.width / 2, -overlay.contentSize.height / 2);
	[self addChild:overlay z:6];
	
	// 60px is the width/height of the minimap
	int minimapSize = 60;
	
	// Draw the minimap on the "win" overlay
	for (int i = 0, j = gridSize * gridSize; i < j; i++)
	{
		int x = i % gridSize;
		int y = floor(i / gridSize);
		if ([[puzzleAnswers objectAtIndex:i] intValue] == kBlockFilled)
		{
			[self drawMinimapAt:ccp(overlay.contentSize.width / 2, overlay.contentSize.height / 2 + (minimapSize / 2 * fontMultiplier))
					  withBlock:ccp(y, x)
						 onNode:overlay];
		}

	}
	
	NSDictionary *level;
	// If the selected level index is within bounds...
	if (currentLevelIndex >= 0 && currentLevelIndex < [levels count])
	{
		level = [levels objectAtIndex:currentLevelIndex];
	}
	// Otherwise, assume it's the tutorial
	else
	{
		level = [NSDictionary dictionaryWithObjectsAndKeys:@"Easy", @"difficulty", @"The letter 'G'", @"title", @"tutorial.tmx", @"filename", nil];
	}
	NSString *levelName = [level objectForKey:@"title"];

	// Create a label that displays the name of the level
	CCLabelTTF *levelNameLabel = [CCLabelTTF labelWithString:levelName fontName:@"slkscr.ttf" fontSize:16 * fontMultiplier];
	levelNameLabel.position = ccp(overlay.contentSize.width / 2, overlay.contentSize.height / 2 - (minimapSize / 2 * fontMultiplier));
	levelNameLabel.color = ccc3(0, 0, 0);
	[overlay addChild:levelNameLabel];
	
	CCMenuItemImage *continueButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"continue-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"continue-button-selected%@.png", hdSuffix] block:^(id sender) {
		// Play SFX
		[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
		
#if kLiteVersion
		// If "lite" version and player has completed all puzzles, the continue button goes to the "upgrade!" scene
		if ([self checkAchievementStatusForDifficulty:@"beginner"] == 100.0)
		{
			CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[UpgradeScene node]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}
		else if (isTutorial)
		{
			// Go back to title scene
			CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[TitleScene node]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}
		else
		{
			// Go back to level select
			CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[LevelSelectScene node]];
			[[CCDirector sharedDirector] replaceScene:transition];	
		}
#else
		if (isTutorial)
		{
			// Go back to title scene
			CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[TitleScene node]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}
		else
		{
			// Go back to level select
			CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[LevelSelectScene node]];
			[[CCDirector sharedDirector] replaceScene:transition];	
		}
#endif
	}];
	
	CCMenu *overlayMenu = [CCMenu menuWithItems:continueButton, nil];
	overlayMenu.position = ccp(overlay.contentSize.width / 2, continueButton.contentSize.height);
	[overlay addChild:overlayMenu];
	
	// Ease overlay on to screen
	id move = [CCMoveTo actionWithDuration:0.5 position:ccp(windowSize.width / 2, windowSize.height / 2)];
	id ease = [CCEaseBackOut actionWithAction:move];
	id particles = [CCCallBlock actionWithBlock:^(void) {
		
		// ask director the the window size
		CGSize windowSize = [CCDirector sharedDirector].winSize;
		
		// Create quad particle system (faster on 3rd gen & higher devices, only slightly slower on 1st/2nd gen)
		CCParticleSystemQuad *particleSystem = [[CCParticleSystemQuad alloc] initWithTotalParticles:500];
		
		// duration is for the emitter
		[particleSystem setDuration:1.0];
		
		[particleSystem setEmitterMode:kCCParticleModeGravity];
		
		// Gravity Mode: gravity
		[particleSystem setGravity:ccp(0, -200 * fontMultiplier)];
		
		// Gravity Mode: speed of particles
		[particleSystem setSpeed:350 * fontMultiplier];
		[particleSystem setSpeedVar:50 * fontMultiplier];
		
		// Gravity Mode: radial
		[particleSystem setRadialAccel:-150];
		[particleSystem setRadialAccelVar:-100];
		
		// Gravity Mode: tagential
		[particleSystem setTangentialAccel:0];
		[particleSystem setTangentialAccelVar:0];
		
		// angle
		[particleSystem setAngle:90];
		[particleSystem setAngleVar:360];
		
		// emitter position
		[particleSystem setPosition:ccp(windowSize.width / 2, windowSize.height / 2)];
		[particleSystem setPosVar:CGPointZero];
		
		// life is for particles particles - in seconds
		[particleSystem setLife:0.5];
		[particleSystem setLifeVar:0.25];
		
		// size, in pixels
		[particleSystem setStartSize:8.0 * fontMultiplier];
		[particleSystem setStartSizeVar:2.0 * fontMultiplier];
		[particleSystem setEndSize:kCCParticleStartSizeEqualToEndSize];
		
		// color of particles
		ccColor4F startColor = {1.0f, 1.0f, 1.0f, 1.0f};
		ccColor4F endColor = {1.0f, 1.0f, 1.0f, 1.0f};
		[particleSystem setStartColor:startColor];
		[particleSystem setEndColor:endColor];
		
		// emits per second
		[particleSystem setEmissionRate:[particleSystem totalParticles] / [particleSystem duration]];

		// Set texture
		[particleSystem setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"filled-square%@.png", hdSuffix]]];
		
		// additive
		[particleSystem setBlendAdditive:NO];
		
		// Auto-remove the emitter when it is done!
		[particleSystem setAutoRemoveOnFinish:YES];
		
		// Add to layer
		[self addChild:particleSystem z:4];
	}];
	
	// Ease overlay on to screen, then create particle explosion behind it
	[overlay runAction:[CCSequence actions:ease, particles, nil]];
	
	// Store time data about level completion if it's not the tutorial
	if (isTutorial == NO)
	{
		// Make mutable dictionary of current level times
		NSMutableDictionary *timeData = [NSMutableDictionary dictionaryWithDictionary:[levelTimes objectAtIndex:currentLevelIndex]];
		
		// Set local vars with the default/current values
		NSNumber *attempts = [[levelTimes objectAtIndex:currentLevelIndex] objectForKey:@"attempts"];
		NSString *firstTime = [[levelTimes objectAtIndex:currentLevelIndex] objectForKey:@"firstTime"];
		NSString *bestTime = [[levelTimes objectAtIndex:currentLevelIndex] objectForKey:@"bestTime"];
		
		// Subtract minute/second values by 29/60 respectively, so that time shown is total time taken, rather than time left
		int minutesLeft = secondsLeft / 60;
		secondsLeft -= minutesLeft * 60;
		NSString *currentTime = [NSString stringWithFormat:@"%@:%@", [NSString stringWithFormat:@"%02d", 29 - minutesLeft], [NSString stringWithFormat:@"%02d", 60 - secondsLeft]];
		
		// Decide if they need to be updated
		if ([firstTime isEqualToString:@"--:--"])
		{
	//		CCLOG(@"Creating first time!");
			[timeData setValue:currentTime forKey:@"firstTime"];
		}
		
		if ([bestTime isEqualToString:@"--:--"])
		{
	//		CCLOG(@"Creating best time!");
			[timeData setValue:currentTime forKey:@"bestTime"];
		}
		
		// If currentTime is lower than bestTime
		if ([currentTime compare:bestTime options:NSNumericSearch] == NSOrderedAscending)
		{
	//		CCLOG(@"Updating best time!");
			[timeData setValue:currentTime forKey:@"bestTime"];
		}
		
		// Increment attempts
		[timeData setValue:[NSNumber numberWithInt:[attempts intValue] + 1] forKey:@"attempts"];
		
		// Re-save
		[levelTimes replaceObjectAtIndex:currentLevelIndex withObject:timeData];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:levelTimes forKey:@"levelTimes"];
		[defaults synchronize];

		
		// Game Center achievement IDs
		// com.ganbarugames.nonogrammadness.beginner
		// com.ganbarugames.nonogrammadness.easy
		// com.ganbarugames.nonogrammadness.medium
		// com.ganbarugames.nonogrammadness.hard
		// com.ganbarugames.nonogrammadness.random_easy
		// com.ganbarugames.nonogrammadness.random_medium
		// com.ganbarugames.nonogrammadness.random_hard

		// If current level index == 110, 111 or 112, increment achievement for random puzzles
		switch (currentLevelIndex)
		{
			case 110:
				// Increment achievement status for random easy - 1/10
				[[GameSingleton sharedGameSingleton] reportAchievementIdentifier:@"com.ganbarugames.nonogrammadness.random_easy" 
														incrementPercentComplete:10.0];
	//			CCLOG(@"Incrementing easy random achievement");
				break;
			case 111:
				// Increment achievement status for random medium - 1/20
				[[GameSingleton sharedGameSingleton] reportAchievementIdentifier:@"com.ganbarugames.nonogrammadness.random_medium" 
														incrementPercentComplete:5.0];
	//			CCLOG(@"Incrementing medium random achievement");
				break;
			case 112:
				// Increment achievement status for random hard - 1/40
				[[GameSingleton sharedGameSingleton] reportAchievementIdentifier:@"com.ganbarugames.nonogrammadness.random_hard" 
														incrementPercentComplete:2.5];
	//			CCLOG(@"Incrementing hard random achievement");
				break;
			default:
			{
				// Get the level dictionary
				NSDictionary *level = [levels objectAtIndex:currentLevelIndex];
				
				// Determine difficulty
				NSString *difficulty = [(NSString *)[level objectForKey:@"difficulty"] lowercaseString];
				
				// Update achievement object for that difficulty with the checkAchievementStatusForDifficulty method
				[[GameSingleton sharedGameSingleton] reportAchievementIdentifier:[NSString stringWithFormat:@"com.ganbarugames.nonogrammadness.%@", difficulty] 
																 percentComplete:[self checkAchievementStatusForDifficulty:difficulty]];
				
	//			CCLOG(@"Setting %@ to %f", [NSString stringWithFormat:@"com.ganbarugames.nonogrammadness.%@", difficulty], [self checkAchievementStatusForDifficulty:difficulty]);
			}
				break;
		}	// End switch (currentLevelIndex)
	}	// End if (isTutorial == NO)
}

/**
 * Actions to take when player has lost a puzzle
 */
- (void)lose
{
	// ask director the the window size
	CGSize windowSize = [CCDirector sharedDirector].winSize;
	
	// Stop the timer countdown
	[self unschedule:@selector(update:)];
	
	// Prevent additional touch events from occurring
	[self setIsTouchEnabled:NO];
	
	// disable the pause button
	[pauseButton setIsEnabled:NO];
	
	// Hide clue "highlights"
	[horizontalClueHighlight runAction:[CCFadeOut actionWithDuration:0.1]];
	[verticalClueHighlight runAction:[CCFadeOut actionWithDuration:0.1]];
	
	// Play "lose" music
	[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"lose.mp3" loop:NO];
	
	CCSprite *overlay = [CCSprite spriteWithFile:[NSString stringWithFormat:@"lose-overlay-background%@.png", hdSuffix]];
	overlay.position = ccp(windowSize.width / 2, -overlay.contentSize.height / 2);
	[self addChild:overlay z:4];
	
	CCMenuItemImage *tryAgainButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"try-again-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"try-again-button-selected%@.png", hdSuffix] block:^(id sender) {
		// Play SFX
		[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
		
		// Reload this scene
		CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[GameScene node]];
		[[CCDirector sharedDirector] replaceScene:transition];
	}];
	
	CCMenuItemImage *quitButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"quit-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"quit-button-selected%@.png", hdSuffix] block:^(id sender) {
		// Play SFX
		[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
		
		if (isTutorial)
		{
			// Go back to title screen
			CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[TitleScene node]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}
		else
		{
			// Go back to level select
			CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[LevelSelectScene node]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}
	}];
	
	CCMenu *overlayMenu = [CCMenu menuWithItems:tryAgainButton, quitButton, nil];
	[overlayMenu alignItemsVerticallyWithPadding:11.0];
	overlayMenu.position = ccp(overlay.contentSize.width / 2, quitButton.contentSize.height * 1.5);
	[overlay addChild:overlayMenu];
	
	// Ease overlay on to screen
	id move = [CCMoveTo actionWithDuration:0.5 position:ccp(windowSize.width / 2, windowSize.height / 2)];
	id ease = [CCEaseBackOut actionWithAction:move];
	[overlay runAction:ease];
	
	if (isTutorial == NO)
	{
		// Load level metadata dictionary
		int currentLevelIndex = [GameSingleton sharedGameSingleton].level;
		
		// Make mutable dictionary of current level times
		NSMutableDictionary *timeData = [NSMutableDictionary dictionaryWithDictionary: [levelTimes objectAtIndex:currentLevelIndex]];
		
		// Set local vars with the default/current values
		NSNumber *attempts = [[levelTimes objectAtIndex:currentLevelIndex] objectForKey:@"attempts"];
		
		// Increment attempts
		[timeData setValue:[NSNumber numberWithInt:[attempts intValue] + 1] forKey:@"attempts"];
		
		// Re-save
		[levelTimes replaceObjectAtIndex:currentLevelIndex withObject:timeData];
		[[NSUserDefaults standardUserDefaults] setObject:levelTimes forKey:@"levelTimes"];
	}
}

/**
 * Unschedule the timer, prevent player touches on the puzzle grid, and cover teh puzzle with an overlay
 */
- (void)pause
{
	paused = YES;
	[self setIsTouchEnabled:NO];
	[self unschedule:@selector(update:)];
	
	// Move overlay into position
	id move = [CCMoveBy actionWithDuration:0.5 position:ccp(pauseOverlay.contentSize.width + iPadOffset.x, 0)];
	id ease = [CCEaseBackOut actionWithAction:move];
	[pauseOverlay runAction:ease];
}

/**
 * Reschedule the timer, reenable player touches on the puzzle grid, and remove overlay
 */
- (void)unpause
{
	paused = NO;
	[self setIsTouchEnabled:YES];
	[self schedule:@selector(update:) interval:1.0];
	
	// Move overlay out of position
	id move = [CCMoveBy actionWithDuration:0.5 position:ccp(pauseOverlay.contentSize.width + iPadOffset.x, 0)];
	id ease = [CCEaseBackOut actionWithAction:move];
	id reset = [CCCallBlock actionWithBlock:^(void) {
		// Reset the position when finished
		pauseOverlay.position = ccp(-pauseOverlay.contentSize.width / 2, pauseOverlay.position.y);
	}];
	[pauseOverlay runAction:[CCSequence actions:ease, reset, nil]];
}

/**
 * Create a TTF label, add to layer, then animate off the screen
 */
- (void)createStatusMessageAt:(CGPoint)position withText:(NSString *)text
{
	int defaultFontSize = 24;
	
	// Create a label and add it to the layer
	CCLabelTTF *label = [CCLabelTTF labelWithString:text fontName:@"slkscr.ttf" fontSize:defaultFontSize * fontMultiplier];
	label.position = position;
	label.color = ccc3(0, 0, 0);
	[self addChild:label z:10];		// Should be z-positioned on top of everything
	
	// Run some move/fade actions
	CCMoveBy *move = [CCMoveBy actionWithDuration:1.5 position:ccp(0, label.contentSize.height)];
	CCEaseBackOut *ease = [CCEaseBackOut actionWithAction:move];
	CCFadeOut *fade = [CCFadeOut actionWithDuration:1];
	CCCallFuncN *remove = [CCCallFuncN actionWithTarget:self selector:@selector(removeNodeFromParent:)];
	
	[label runAction:[CCSequence actions:[CCSpawn actions:ease, fade, nil], remove, nil]];
}

/**
 * Shows a blob of text over a "window" background, then animates it on to the screen
 * (sprite and label vars are class properties)
 */
- (void)showTextWindowAt:(CGPoint)position withText:(NSString *)text
{
	// Create the background sprite if it doesn't exist
	if (!textWindowBackground)
	{
		textWindowBackground = [CCSprite spriteWithFile:[NSString stringWithFormat:@"text-window-background%@.png", hdSuffix]];
		[self addChild:textWindowBackground z:5];		// Should be on top of everything
	}
	
	// Create the label if it doesn't exist
	if (!textWindowLabel)
	{
		int defaultFontSize = 12;
		textWindowLabel = [CCLabelTTF labelWithString:text dimensions:CGSizeMake(textWindowBackground.contentSize.width - 20 * fontMultiplier, textWindowBackground.contentSize.height - 20 * fontMultiplier) alignment:CCTextAlignmentLeft fontName:@"pf_westa_seven.ttf" fontSize:defaultFontSize * fontMultiplier];
		textWindowLabel.position = ccp(textWindowBackground.contentSize.width / 2, textWindowBackground.contentSize.height / 2);
		textWindowLabel.color = ccc3(0, 0, 0);
		[textWindowBackground addChild:textWindowLabel];
	}
	// Otherwise, just update its' text
	else
	{
		[textWindowLabel setString:text];
	}
	
	// Hide the window initially
	textWindowBackground.opacity = 0;
	
	// Hide the text initially
	textWindowLabel.opacity = 0;
	
	// Position below its' intended final location
	textWindowBackground.position = ccp(position.x, position.y - (100 * fontMultiplier));
	
	id move = [CCMoveTo actionWithDuration:0.4 position:position];
	id ease = [CCEaseBackOut actionWithAction:move];
	id fadeIn = [CCFadeIn actionWithDuration:0.3];
	
	[textWindowBackground runAction:[CCSpawn actions:ease, fadeIn, nil]];
	[textWindowLabel runAction:[CCFadeIn actionWithDuration:0.3]];
}

/**
 * Animates the text window off screen
 */
- (void)dismissTextWindow
{
	id fadeOut = [CCFadeOut actionWithDuration:0.2];
	id move = [CCMoveTo actionWithDuration:0.4 position:ccp(textWindowBackground.position.x, textWindowBackground.position.y - (100 * fontMultiplier))];
	
	[textWindowBackground runAction:[CCSpawn actions:move, fadeOut, nil]];
	[textWindowLabel runAction:[CCFadeOut actionWithDuration:0.2]];
}

/**
 * Create a particle effect at a CGPoint position
 */
- (void)createParticlesAt:(CGPoint)position
{
	int particleCount;
	if (action == kActionFill)
	{
		particleCount = 25;
	}
	else if (action == kActionMark)
	{
		particleCount = 10;
	}
	
	// Create quad particle system (faster on 3rd gen & higher devices, only slightly slower on 1st/2nd gen)
	CCParticleSystemQuad *particleSystem = [[CCParticleSystemQuad alloc] initWithTotalParticles:particleCount];
	
	// duration is for the emitter
	[particleSystem setDuration:0.25f];
	
	[particleSystem setEmitterMode:kCCParticleModeGravity];
	
	// Gravity Mode: gravity
	[particleSystem setGravity:ccp(0, -400)];
	
	// Gravity Mode: speed of particles
	[particleSystem setSpeed:140];
	[particleSystem setSpeedVar:40];
	
	// Gravity Mode: radial
	[particleSystem setRadialAccel:-150];
	[particleSystem setRadialAccelVar:-100];
	
	// Gravity Mode: tagential
	[particleSystem setTangentialAccel:0];
	[particleSystem setTangentialAccelVar:0];
	
	// angle
	[particleSystem setAngle:90];
	[particleSystem setAngleVar:360];
	
	// emitter position
	[particleSystem setPosition:position];
	[particleSystem setPosVar:CGPointZero];
	
	// life is for particles particles - in seconds
	[particleSystem setLife:0.5];
	[particleSystem setLifeVar:0.25];
	
	// size, in pixels
	[particleSystem setStartSize:8.0 * fontMultiplier];
	[particleSystem setStartSizeVar:2.0 * fontMultiplier];
	[particleSystem setEndSize:kCCParticleStartSizeEqualToEndSize];
	
	// emits per second
	[particleSystem setEmissionRate:[particleSystem totalParticles] / [particleSystem duration]];
	
	// color of particles
	ccColor4F startColor = {1.0f, 1.0f, 1.0f, 1.0f};
	ccColor4F endColor = {1.0f, 1.0f, 1.0f, 1.0f};
	[particleSystem setStartColor:startColor];
	[particleSystem setEndColor:endColor];
	
	if (action == kActionFill)
	{
		[particleSystem setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"filled-square%@.png", hdSuffix]]];
	}
	else if (action == kActionMark)
	{
		[particleSystem setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"marked-square%@.png", hdSuffix]]];
	}
	
	// [[CCTextureCache sharedTextureCache] textureForKey:@"particle.png"]];
	
	// additive
	[particleSystem setBlendAdditive:NO];
	
	// Auto-remove the emitter when it is done!
	[particleSystem setAutoRemoveOnFinish:YES];
	
	// Add to layer
	[self addChild:particleSystem z:5];
}

/**
 * Method that is chained at the end of action sequences to remove a sprite after it has been displayed
 */
- (void)removeNodeFromParent:(CCNode *)node
{
	[node.parent removeChild:node cleanup:YES];
}

/**
 * Loops through level time metadata and determines completion status for the 6 achievements in v.2
 */
- (float)checkAchievementStatusForDifficulty:(NSString *)difficulty
{
	float achievementStatus = 100.0;
	
	// LEVEL INDICES
	// Beginner: 0 - 9
	// Easy: 10 - 36, 100 - 101
	// Medium: 37 - 76, 102
	// Hard: 77 - 99, 103 - 109
	
	// Cycle through time metadata and determine which levels have been completed
	if ([difficulty isEqualToString:@"beginner"])
	{
		float count = 0;
		float total = 10;
		for (int i = 0; i <= 9; i++)
		{
			// If level has been successfully completed, increment the counter
			if (![[[levelTimes objectAtIndex:i] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
			{
				count++;
			}
		}
		
		if (count != total)
		{
			achievementStatus = count / total * 100;
		}
	}
	// Check "easy" puzzles
	else if ([difficulty isEqualToString:@"easy"])
	{
		float count = 0;
		float total = 29;
		for (int i = 10; i <= 36; i++)
		{
			// If level has been successfully completed, increment the counter
			if (![[[levelTimes objectAtIndex:i] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
			{
				count++;
			}
		}
		
		for (int i = 100; i <= 101; i++)
		{
			// If level has been successfully completed, increment the counter
			if (![[[levelTimes objectAtIndex:i] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
			{
				count++;
			}
		}
		
		if (count != total)
		{
			achievementStatus = count / total * 100;
		}
	}
	// Check "medium" puzzles
	else if ([difficulty isEqualToString:@"medium"])
	{
		float count = 0;
		float total = 41;
		for (int i = 37; i <= 76; i++)
		{
			// If level has been successfully completed, increment the counter
			if (![[[levelTimes objectAtIndex:i] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
			{
				count++;
			}
		}
		
		for (int i = 102; i <= 102; i++)
		{
			// If level has been successfully completed, increment the counter
			if (![[[levelTimes objectAtIndex:i] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
			{
				count++;
			}
		}
		
		if (count != total)
		{
			achievementStatus = count / total * 100;
		}
	}
	else if ([difficulty isEqualToString:@"hard"])
	{
		float count = 0;
		float total = 30;
		for (int i = 77; i <= 99; i++)
		{
			// If level has been successfully completed, increment the counter
			if (![[[levelTimes objectAtIndex:i] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
			{
				count++;
			}
		}
		
		for (int i = 103; i <= 109; i++)
		{
			// If level has been successfully completed, increment the counter
			if (![[[levelTimes objectAtIndex:i] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
			{
				count++;
			}
		}
		
		if (count != total)
		{
			achievementStatus = count / total * 100;
		}
	}
	
	return achievementStatus;
}

// on "dealloc" you need to release all your retained objects
- (void)dealloc
{
	[levels release];
	[levelTimes release];
	
	[puzzleAnswers release];
	[gridStatus release];
	[gridSprites release];
	
	[horizontalClues release];
	[verticalClues release];
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
