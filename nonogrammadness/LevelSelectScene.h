//
//  LevelSelectScene.h
//  nonogrammadness
//
//  Created by Nathan Demick on 8/31/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface LevelSelectScene : CCLayer 
{
	// The "page" of levels being displayed
	int currentPage;
	
	// # of sprites per page! it'll be 9, FYI
	int spritesPerPage;
	
	// Buttons that cycle through levels
	CCMenuItemImage *prevButton, *nextButton;
	
	// Variable set to "true" if level preview icons are in motion
	BOOL transitioning;
	
	// A highlight graphic around the currently selected level
	CCSprite *selectedHighlight;
	
	// Array of completion times 
	NSArray *puzzleTimes;
	
	// Load an array of puzzle names & filenames
	NSMutableArray *puzzleList;
	
	// puzzleSprites contains a sprite of each level, loaded lazily
	NSMutableArray *puzzleSprites;
	
	// Display level metadata
	CCLabelTTF *levelNumberLabel, *nameLabel, *difficultyLabel, *attemptsLabel, *bestTimeLabel;
	
	// String to be appended to sprite filenames if required to use a high-rez file (e.g. iPhone 4 assests on iPad)
	NSString *hdSuffix;
	int fontMultiplier;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+ (CCScene *)scene;

- (void)removeNodeFromParent:(CCNode *)node;

// Loads a level "page" and displays the sprites at a certain position either on or off screen
- (void)loadPage:(int)page atPosition:(CGPoint)position;
- (void)showPreviousPage;
- (void)showNextPage;
- (void)showMetadataForLevel:(int)i;

@end
