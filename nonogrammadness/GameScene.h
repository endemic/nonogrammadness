//
//  GameScene.h
//  nonogrammadness
//
//  Created by Nathan Demick on 8/31/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameScene : CCLayer 
{
	// A sprite used as a background for a popup text window
	CCSprite *textWindowBackground;
	
	// Text that appears on popup text window
	CCLabelTTF *textWindowLabel;
	
	// Simple bool to check whether the tutorial is happening
	BOOL isTutorial;
	
	// Tracks the progress of the in-game tutorial
	int tutorialStep;
	
	// Allows player to progress through the tutorial instructions
	CCMenu *tutorialMenu;
	CCMenuItemImage *tutorialButton;
	
	// Highlights correct answers to progress thru tutorial
	CCSprite *tutorialHighlight;
	
	// Currently selected player action - "mark" or "fill", as well as whether the current touch should add or remove "marks"
	int action, actionLock;
	
	// Buttons that reference the selected player action
	CCMenuItemImage *markButton, *fillButton;
	
	// Keeps track of correct/incorrect guesses
	int hits, misses, totalHits;
	
	// Keeps track of time remaining for puzzle to be solved
	int secondsLeft;
	
	// Info about the playing grid
	int rows, cols, blockSize, gridSize, maxGridSize;
	
	// Status labels showing game progress
	CCLabelBMFont *timerLabel, *percentCompleteLabel;
	
	// Overlay that obscures the puzzle when teh game is paused
	CCMenuItemImage *pauseButton;
	CCSprite *pauseOverlay;
	BOOL paused;
	
	// Arrays that hold the level metadata and time data
	NSArray *levels;
	NSMutableArray *levelTimes;
	
	// Map layer that contains the loaded puzzle data
	NSMutableArray *puzzleAnswers;
	
	// Array that contains the status of each block in the puzzle grid; i.e. whether it's blank, marked, or filled
	NSMutableArray *gridStatus;
	
	// Array that holds the mark/fill sprites that appear over the puzzle grid
	NSMutableArray *gridSprites;
	
	// Arrays that store puzzle clues
	NSMutableArray *horizontalClues, *verticalClues;
	
	// Appear in the row/column that is currently being touched
	CCSprite *horizontalClueHighlight, *verticalClueHighlight;
	
	// Variables that store user interaction points
	CGPoint touchStart, touchPrevious;
	int touchRow, touchCol, previousRow, previousCol;
	
	// On iPhone/iPod Touch (with smaller screens), lock multiple touches to the touched row/column, to prevent
	// accidental actions
	int lockedRow, lockedCol;
	
	// Values used to offset the grid position so that touches can be calculated as if the grid was at the origin
	CGPoint gridOffset;
	
	// String to be appended to sprite filenames if required to use a high-rez file (e.g. iPhone 4 assests on iPad)
	NSString *hdSuffix;
	int fontMultiplier;
	
	// Extra pixels that are added due to iPad's larger resolution
	// Used when calculating touch positions on puzzle grid, as well as when placing UI objects
	CGPoint iPadOffset;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+ (CCScene *)scene;

- (void)loadPuzzleWithFile:(NSString *)filename;
- (void)actionOnRow:(int)row andCol:(int)col;
- (void)generateClues;
- (void)checkCompletedCluesForRow:(int)row andCol:(int)col;
- (void)drawMinimapAt:(CGPoint)position withBlock:(CGPoint)block onNode:(CCNode *)node;

- (void)createParticlesAt:(CGPoint)position;
- (void)createStatusMessageAt:(CGPoint)position withText:(NSString *)text;
- (void)removeNodeFromParent:(CCNode *)node;

- (void)win;
- (void)lose;
- (void)pause;
- (void)unpause;

- (float)checkAchievementStatusForDifficulty:(NSString *)difficulty;

- (void)showTutorial;
- (void)showTextWindowAt:(CGPoint)position withText:(NSString *)text;
- (void)dismissTextWindow;

@end
