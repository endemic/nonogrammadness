//
//  LevelSelectScene.m
//  nonogrammadness
//
//  Created by Nathan Demick on 8/31/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import "LevelSelectScene.h"
#import "GameScene.h"
#import "TitleScene.h"

#import "GameSingleton.h"
#import "SimpleAudioEngine.h"
#import "GameConfig.h"

#define kTransitionDuration 0.5

@implementation LevelSelectScene
+ (CCScene *)scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	LevelSelectScene *layer = [LevelSelectScene node];
	
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
		[self setIsTouchEnabled:YES];
		
		// ask director the the window size
		CGSize windowSize = [CCDirector sharedDirector].winSize;
		
		// This string gets appended onto all image filenames based on whether the game is on iPad or not
		if ([GameSingleton sharedGameSingleton].isPad)
		{
			hdSuffix = @"-hd";
			fontMultiplier = 2;
		}
		else
		{
			hdSuffix = @"";
			fontMultiplier = 1;
		}
		
		// Create/add background
		CCSprite *bg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"background%@.png", hdSuffix]];
		bg.position = ccp(windowSize.width / 2, windowSize.height / 2);
		[self addChild:bg z:0];
		
		// Add some buttons
		CCMenuItemImage *startButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"start-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"start-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play sound effect
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			// Transition to level select
			CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[GameScene node]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		
		CCMenu *titleMenu = [CCMenu menuWithItems:startButton, nil];
		titleMenu.position = ccp(windowSize.width / 2, startButton.contentSize.height);
		[self addChild:titleMenu z:1];
		
		// Set up back & achievements buttons
		CCMenuItemImage *backButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"back-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"back-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play sound effect
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			// Stop playing music
			[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
			
			// Transition to title screen
			CCTransitionTurnOffTiles *transition = [CCTransitionTurnOffTiles transitionWithDuration:0.5 scene:[TitleScene node]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		
		CCMenuItemImage *achievementsButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"achievements-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"achievements-button-selected%@.png", hdSuffix] disabledImage:[NSString stringWithFormat:@"achievements-button-disabled%@.png", hdSuffix] block:^(id sender) {
			// Play sound effect
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			// Call up Game Center overlay
			[[GameSingleton sharedGameSingleton] showAchievements];
		}];
		
		// Disable the achievements button if no Game Center
		if ([GameSingleton sharedGameSingleton].hasGameCenter == NO)
		{
			[achievementsButton setIsEnabled:NO];
		}
		
		CCMenu *topMenu = [CCMenu menuWithItems:backButton, achievementsButton, nil];
		[topMenu alignItemsHorizontallyWithPadding:80 * fontMultiplier];
		topMenu.position = ccp(windowSize.width / 2, windowSize.height - backButton.contentSize.height);
		[self addChild:topMenu z:2];
		
		// Set up the previous/next buttons
		prevButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"previous-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"previous-button-selected%@.png", hdSuffix] disabledImage:[NSString stringWithFormat:@"previous-button-disabled%@.png", hdSuffix] block:^(id sender) {
			// Trigger animations that slide in levels from off screen
			[self showPreviousPage];

			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
		}];
		
		nextButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"next-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"next-button-selected%@.png", hdSuffix] disabledImage:[NSString stringWithFormat:@"next-button-disabled%@.png", hdSuffix] block:^(id sender) {
			// Trigger animations that slide in levels from off screen
			[self showNextPage];

			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
		}];	
		
		CCMenu *prevNextMenu = [CCMenu menuWithItems:prevButton, nextButton, nil];
		[prevNextMenu alignItemsHorizontallyWithPadding:220 * fontMultiplier];
		prevNextMenu.position = ccp(windowSize.width / 2, windowSize.height / 1.5);
		[self addChild:prevNextMenu z:2];
		
		// Load an array of best times for puzzles
		puzzleTimes = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"] retain];
		
		// Load an array of puzzle names & filenames
		puzzleList = [[NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Levels" ofType:@"plist"]] retain];
		
#if kLiteVersion
		// Limit the puzzle list if compiled as "lite" version
		for (int i = [puzzleList count] - 1; i >= 10; i--)
		{
			[puzzleList removeObjectAtIndex:i];
		}
#endif
		
		// puzzleSprites contains a sprite of each level, loaded lazily
		puzzleSprites = [[NSMutableArray arrayWithCapacity:[puzzleList count]] retain];
		
		// Defaults are null
		for (int i = 0, j = [puzzleList count]; i < j; i++)
		{
			[puzzleSprites addObject:[NSNull null]];
		}
		
		// Create the "currently selected" highlight, hide it, then add to layer
		selectedHighlight = [CCSprite spriteWithFile:[NSString stringWithFormat:@"selected-puzzle-highlight%@.png", hdSuffix]];
		[self addChild:selectedHighlight z:2];
		
		// Set how many sprites will be displayed by default
		spritesPerPage = 9;
		
		// Set currently displayed page
		currentPage = floor([GameSingleton sharedGameSingleton].level / spritesPerPage) + 1;	// Argh, stupidly I have the page starting at 1 instead of 0
		
		// Not currently moving between levels
		transitioning = NO;
		
		// Load the first page of sprites
		[self loadPage:currentPage atPosition:ccp(windowSize.width / 2, windowSize.height / 1.5)];
		
		// Create labels that show puzzle metadata/best times
		NSDictionary *timedata = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"] objectAtIndex:[GameSingleton sharedGameSingleton].level];
		NSDictionary *metadata = [puzzleList objectAtIndex:[GameSingleton sharedGameSingleton].level];
		
		int defaultFontSize = 24;
		
		// Best time
		bestTimeLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Best Time: %@", [timedata objectForKey:@"bestTime"]] 
										   fontName:@"slkscr.ttf" 
										   fontSize:defaultFontSize * fontMultiplier];
		bestTimeLabel.position = ccp(windowSize.width / 2, titleMenu.position.y + bestTimeLabel.contentSize.height * 2);
		[self addChild:bestTimeLabel z:2];
		
		// # of attempts
		attemptsLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Attempts: %@", [timedata objectForKey:@"attempts"]] 
										   fontName:@"slkscr.ttf" 
										   fontSize:defaultFontSize * fontMultiplier];
		attemptsLabel.position = ccp(windowSize.width / 2, bestTimeLabel.position.y + attemptsLabel.contentSize.height);
		[self addChild:attemptsLabel z:2];
		
		// Difficulty
		difficultyLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Difficulty: %@", [metadata objectForKey:@"difficulty"]] 
											 fontName:@"slkscr.ttf" 
											 fontSize:defaultFontSize * fontMultiplier];
		difficultyLabel.position = ccp(windowSize.width / 2, attemptsLabel.position.y + difficultyLabel.contentSize.height);
		[self addChild:difficultyLabel z:2];
		
		// Name - only show the title of a level if the player has already beaten it
		NSString *name;
		if ([[timedata objectForKey:@"firstTime"] isEqualToString:@"--:--"])
		{
			 name = @"??????";
		}
		else
		{
			name = [metadata objectForKey:@"title"];
		}
		nameLabel = [CCLabelTTF labelWithString:name
									   fontName:@"slkscr.ttf" 
									   fontSize:defaultFontSize * fontMultiplier];
		nameLabel.position = ccp(windowSize.width / 2, difficultyLabel.position.y + nameLabel.contentSize.height);
		[self addChild:nameLabel z:2];
		
		// Level #
		levelNumberLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Level %i", [GameSingleton sharedGameSingleton].level + 1]	// The stored level int is an array index
											  fontName:@"slkscr.ttf" 
											  fontSize:defaultFontSize * fontMultiplier];
		levelNumberLabel.position = ccp(windowSize.width / 2, nameLabel.position.y + levelNumberLabel.contentSize.height);
		[self addChild:levelNumberLabel z:2];
		
		
		// Play music
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"tutorial.mp3"];
	}
	return self;
}

/*
 * Intercept touches, and determine if they are within the bounds of a puzzle preview sprite. If so, move the 
 * "highlight" sprite over the preview and load the level info
 */
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Get the touch coords
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
	
	int start = (currentPage - 1) * spritesPerPage;
	int end = start + spritesPerPage;
	
	// Enforce the end position to be the size of the sprite array
	if (end > [puzzleSprites count])
	{
		end = [puzzleSprites count];
	}
	
	// Loop thru them to determine whether the touch was within any of their bounds
	for (int i = start; i < end; i++)
	{
		CCSprite *s = [puzzleSprites objectAtIndex:i];
		
		// CGRect origin is at 0, 0, not midpoint
		CGRect spriteBounds = CGRectMake(s.position.x - (s.contentSize.width / 2), s.position.y - (s.contentSize.height / 2), s.contentSize.width, s.contentSize.height);
		CGRect touchBounds = CGRectMake(touchPoint.x, touchPoint.y, 1, 1);		// 1x1 square
		
		// If touching a level preview, set "current level" to be i, and move the "highlight" sprite
		if (CGRectIntersectsRect(spriteBounds, touchBounds))
		{
			// Offset the position of the highlight slightly to account for the "drop shadow" on each preview sprite, which is 2px (4px for iPad)
			CGPoint newHighlightPosition = ccpAdd(s.position, ccp(-1 * fontMultiplier, 1 * fontMultiplier));
			
			id move = [CCMoveTo actionWithDuration:0.5 position:newHighlightPosition];
			id ease = [CCEaseBackOut actionWithAction:move];
			[selectedHighlight runAction:ease];
			
			// Set the currently selected level
			[GameSingleton sharedGameSingleton].level = i;
		
			[self showMetadataForLevel:i];
			
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
			
			break;
		}
	}
}

- (void)showMetadataForLevel:(int)i
{
	// Display the metadata for the selected level
	NSDictionary *timedata = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"] objectAtIndex:i];
	NSDictionary *metadata = [puzzleList objectAtIndex:i];
	
	[difficultyLabel setString:[NSString stringWithFormat:@"Difficulty: %@", [metadata objectForKey:@"difficulty"]]];
	[attemptsLabel setString:[NSString stringWithFormat:@"Attempts: %@", [timedata objectForKey:@"attempts"]]];
	[bestTimeLabel setString:[NSString stringWithFormat:@"Best Time: %@", [timedata objectForKey:@"bestTime"]]];
	
	// Only show the title of a level if the player has already beaten it
	NSString *name;
	if ([[timedata objectForKey:@"firstTime"] isEqualToString:@"--:--"])
	{
		name = @"??????";
	}
	else
	{
		name = [metadata objectForKey:@"title"];
	}
	[nameLabel setString:name];
	
	// Level #
	[levelNumberLabel setString:[NSString stringWithFormat:@"Level %i", [GameSingleton sharedGameSingleton].level + 1]];
}

- (void)showPreviousPage
{
	int previousPage = currentPage - 1;
	
	// Only execute this method if previous page is valid
	if (previousPage > 0) 
	{
		// Disable touch until the transition is complete
		[self setIsTouchEnabled:NO];
		
		// Disable buttons
		[nextButton setIsEnabled:NO];
		[prevButton setIsEnabled:NO];
		
		// Fade out the "selected" cursor
		selectedHighlight.opacity = 0;
		
		// ask director the the window size
		CGSize windowSize = [CCDirector sharedDirector].winSize;
		
		int currentPageIndex = currentPage - 1;
		int previousPageIndex = currentPageIndex - 1;
		
		int start = currentPageIndex * spritesPerPage;
		int end = start + spritesPerPage;
		
		if (end > [puzzleSprites count])
		{
			end = [puzzleSprites count];
		}
		
		// Move currently displayed sprites to the right, then remove them from the layer
		for (int i = start; i < end; i++)
		{
			CCSprite *s = [puzzleSprites objectAtIndex:i];
			id wait = [CCDelayTime actionWithDuration:(float)(spritesPerPage - i % spritesPerPage) / 20.0];
			id move = [CCMoveBy actionWithDuration:kTransitionDuration position:ccp(windowSize.width, 0)];
			id ease = [CCEaseBackOut actionWithAction:move];
			id remove = [CCCallFuncN actionWithTarget:self selector:@selector(removeNodeFromParent:)];
			[s runAction:[CCSequence actions:wait, ease, remove, nil]];
		}
		
		// Load new sprites off screen to the left
		[self loadPage:previousPage atPosition:ccp(-windowSize.width / 2, windowSize.height / 1.5)];
		
		// Move new sprites into position
		start = previousPageIndex * spritesPerPage;
		end = start + spritesPerPage;
		
		for (int i = start; i < end; i++)
		{
			CCSprite *s = [puzzleSprites objectAtIndex:i];
			id wait = [CCDelayTime actionWithDuration:(float)(spritesPerPage - i % spritesPerPage) / 20.0 + 0.2];	// Add slight extra delay so pages don't overlap
			id move = [CCMoveBy actionWithDuration:kTransitionDuration position:ccp(windowSize.width, 0)];
			id ease = [CCEaseBackOut actionWithAction:move];
			id enableTouch = [CCCallBlock actionWithBlock:^(void) {
				[self setIsTouchEnabled:YES];
				[nextButton setIsEnabled:YES];
				[prevButton setIsEnabled:YES];
			}];
			
			// Re-enable touch on the layer after the last level icon slides into place
			if (i == end - 1)
			{
				[s runAction:[CCSequence actions:wait, ease, enableTouch, nil]];
			}
			else
			{
				[s runAction:[CCSequence actions:wait, ease, nil]];
			}
			
			// Run the same first action on the "selected" cursor as well
			if (i == start)
			{
				selectedHighlight.opacity = 255;
				[selectedHighlight runAction:[CCSequence actions:[CCDelayTime actionWithDuration:(float)(spritesPerPage - i % spritesPerPage) / 20.0 + 0.2], [CCEaseBackOut actionWithAction:[CCMoveBy actionWithDuration:kTransitionDuration position:ccp(windowSize.width, 0)]], nil]];
			}
		}
		
		// Set current page
		currentPage = previousPage;
	}
}

- (void)showNextPage
{
	int nextPage = currentPage + 1;
	int maxPages = ceil((float)[puzzleSprites count] / (float)spritesPerPage);

	// Only execute this method if previous page is valid
	if (nextPage <= maxPages) 
	{
		// Disable layer touches until transition is complete
		[self setIsTouchEnabled:NO];
		
		// Disable buttons
		[prevButton setIsEnabled:NO];
		[nextButton setIsEnabled:NO];
		
		// Hide the "selected" cursor
		selectedHighlight.opacity = 0;
		
		// ask director the the window size
		CGSize windowSize = [CCDirector sharedDirector].winSize;
		
		int currentPageIndex = currentPage - 1;
		int nextPageIndex = currentPageIndex + 1;
		
		int start = currentPageIndex * spritesPerPage;
		int end = start + spritesPerPage;
		
		// Move currently displayed sprites to the left, then remove them from the layer
		for (int i = start; i < end; i++)
		{
			CCSprite *s = [puzzleSprites objectAtIndex:i];
			id wait = [CCDelayTime actionWithDuration:(float)(i % spritesPerPage) / 20.0];
			id move = [CCMoveBy actionWithDuration:kTransitionDuration position:ccp(-windowSize.width, 0)];
			id ease = [CCEaseBackOut actionWithAction:move];
			id remove = [CCCallFuncN actionWithTarget:self selector:@selector(removeNodeFromParent:)];
			[s runAction:[CCSequence actions:wait, ease, remove, nil]];
		}
		
		// Load new sprites off screen to the right
		[self loadPage:nextPage atPosition:ccp(windowSize.width * 1.5, windowSize.height / 1.5)];
		
		// Move new sprites into position
		start = nextPageIndex * spritesPerPage;
		end = start + spritesPerPage;
		
		// Enforce the end position to be the size of the sprite array
		if (end > [puzzleSprites count])
		{
			end = [puzzleSprites count];
		}
		
		for (int i = start; i < end; i++)
		{
			CCSprite *s = [puzzleSprites objectAtIndex:i];
			id wait = [CCDelayTime actionWithDuration:(float)(i % spritesPerPage) / 20.0 + 0.2];	// Add slight extra delay so pages don't overlap
			id move = [CCMoveBy actionWithDuration:kTransitionDuration position:ccp(-windowSize.width, 0)];
			id ease = [CCEaseBackOut actionWithAction:move];
			
			id enableTouch = [CCCallBlock actionWithBlock:^(void) {
				[self setIsTouchEnabled:YES];
				[prevButton setIsEnabled:YES];
				[nextButton setIsEnabled:YES];
			}];
			
			// Re-enable touch on the layer after the last level icon slides into place
			if (i == end - 1)
			{
				[s runAction:[CCSequence actions:wait, ease, enableTouch, nil]];
			}
			else
			{
				[s runAction:[CCSequence actions:wait, ease, nil]];
			}
			
			// Run the same first action on the "selected" cursor as well
			if (i == start)
			{
				selectedHighlight.opacity = 255;
				[selectedHighlight runAction:[CCSequence actions:[CCDelayTime actionWithDuration:(float)(i % spritesPerPage) / 20.0 + 0.2], 
											  [CCEaseBackOut actionWithAction:[CCMoveBy actionWithDuration:kTransitionDuration position:ccp(-windowSize.width, 0)]], nil]];
			}
		}
		
		// Set current page
		currentPage = nextPage;
	}
}

/*
 * Creates sprite objects designating puzzle previews, and adds them to the layer at a specified location
 */
- (void)loadPage:(int)page atPosition:(CGPoint)position
{
	// Determine what array indices the page arguement represents
	int pageIndex = page - 1;
	
	int start = pageIndex * spritesPerPage;
	int end = start + spritesPerPage;
	
	// Enforce the end position to be the size of the sprite array
	if (end > [puzzleSprites count])
	{
		end = [puzzleSprites count];
	}
	
	// Load the first 9 level sprites
	for (int i = start; i < end; i++)
	{
		CCSprite *s;
		
		// Load puzzle sprites into the array
		if ([puzzleSprites objectAtIndex:i] == [NSNull null])
		{
			// Decide whether to display the level preview or the question mark
			if ([[[puzzleTimes objectAtIndex:i] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
			{
				// Load question mark
				s = [CCSprite spriteWithFile:[NSString stringWithFormat:@"level-preview-incomplete%@.png", hdSuffix]];
			}
			else
			{
				// Load "blank" background sprite, which will have the TMX file layered on top
				s = [CCSprite spriteWithFile:[NSString stringWithFormat:@"level-preview%@.png", hdSuffix]];
				
				// Get puzzle data
				NSDictionary *puzzle = [puzzleList objectAtIndex:i];
				
				// Create TMX sprite
				CCTMXTiledMap *map = [CCTMXTiledMap tiledMapWithTMXFile:[puzzle objectForKey:@"filename"]];
				
				// Set correct position for map
				map.position = ccp(5 * fontMultiplier, 6 * fontMultiplier);
				
				// Max size is 200x200 (20px square x 10x10 grid)
				int maxPuzzleSize = 10;
				int smallPuzzleScale = maxPuzzleSize - map.mapSize.width == 0 ? 1 : 2;	// Doubles the size of the preview if 5x5
				map.scale = 0.20 * fontMultiplier * smallPuzzleScale;	// 40x40
				
				// Add TMX on top of background sprite
				[s addChild:map];
			}
			
			// Add the sprite to the list of sprites
			[puzzleSprites replaceObjectAtIndex:i withObject:s];
		}
		// Otherwise, use the previously instantiated sprite object that's been stored in the puzzleSprites array
		else
		{
			s = [puzzleSprites objectAtIndex:i];
		}
		
		// The center point which the 9 icons will cluster around
		CGPoint point = position;
		
		// Spacing between the icons
		int spacing = 10 * fontMultiplier;
		
		// Programatically determine the position of each sprite
		
		/*
		 0 = -x, +y
		 1 = 0, +y
		 2 = x, +y
		 3 = -x, 0
		 4 = 0, 0
		 5 = x, 0
		 6 = -x, -y
		 7 = 0, -y
		 8 = x, -y
		 */
		
		/*
		 switch (i % 3)
		 if 0, -x
		 if 1, 0
		 if 2, x
		 */
		
		/*
		 switch floor(i / 3)
		 if 0, +y
		 if 1, 0
		 if 2, -y
		 */
		
		switch ((i % spritesPerPage) % 3)
		{
			case 0:
				point = ccpSub(point, ccp(s.contentSize.width + spacing, 0));
				break;
			case 1:
				// Don't have to add anything to the x value here
				break;
			case 2: 
				point = ccpAdd(point, ccp(s.contentSize.width + spacing, 0));
				break;
		}
		
		switch ((i % spritesPerPage) / 3)
		{
			case 0:
				point = ccpAdd(point, ccp(0, s.contentSize.height + spacing));
				break;
			case 1:
				// Don't have to add anything to the y value here
				break;
			case 2: 
				point = ccpSub(point, ccp(0, s.contentSize.height + spacing));
				break;
		}
		
		// Have the cursor hover over the previously chosen level if possible
		int currentLevel = [GameSingleton sharedGameSingleton].level;
		if (currentLevel >= start && currentLevel < end)
		{
			if (currentLevel == i)
			{
				// Offset the position of the highlight slightly to account for the "drop shadow" on each preview sprite, which is 2px (4px for iPad)
				selectedHighlight.position = ccpAdd(point, ccp(-1 * fontMultiplier, 1 * fontMultiplier));
				
				// Show the level data for that level
				[self showMetadataForLevel:i];
			}
		}
		// Otherwise, move the "highlight" cursor to be over the first (upper left) puzzle icon
		else if (i % spritesPerPage == 0)
		{
			// Offset the position of the highlight slightly to account for the "drop shadow" on each preview sprite, which is 2px (4px for iPad)
			selectedHighlight.position = ccpAdd(point, ccp(-1 * fontMultiplier, 1 * fontMultiplier));
			
			// Set the currently selected level
			[GameSingleton sharedGameSingleton].level = i;
			
			// Show the level data for that level
			[self showMetadataForLevel:i];
		}
		
		// Set the position of the puzzle sprite, and add to layer
		s.position = point;
		
		[self addChild:s z:1];
	}
}

/**
 * This cleanup method gets called by an action for a sprite, which removes it from the current layer. 
 */
- (void)removeNodeFromParent:(CCNode *)node
{
	[node.parent removeChild:node cleanup:YES];
}

// on "dealloc" you need to release all your retained objects
- (void)dealloc
{
	[puzzleTimes release];
	[puzzleList release];
	[puzzleSprites release];
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
