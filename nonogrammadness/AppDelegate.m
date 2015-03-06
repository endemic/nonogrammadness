//
//  AppDelegate.m
//  nonogrammadness
//
//  Created by Nathan Demick on 8/31/11.
//  Copyright Ganbaru Games 2011. All rights reserved.
//

#import "cocos2d.h"
#import "SimpleAudioEngine.h"

#import "AppDelegate.h"
#import "GameConfig.h"
#import "LogoScene.h"
#import "GameScene.h"
#import "RootViewController.h"

#import "GameSingleton.h"

@implementation AppDelegate

@synthesize window;

- (void) removeStartupFlicker
{
	//
	// THIS CODE REMOVES THE STARTUP FLICKER
	//
	// Uncomment the following code if you Application only supports landscape mode
	//
#if GAME_AUTOROTATION == kGameAutorotationUIViewController

//	CC_ENABLE_DEFAULT_GL_STATES();
//	CCDirector *director = [CCDirector sharedDirector];
//	CGSize size = [director winSize];
//	CCSprite *sprite = [CCSprite spriteWithFile:@"Default.png"];
//	sprite.position = ccp(size.width/2, size.height/2);
//	sprite.rotation = -90;
//	[sprite visit];
//	[[director openGLView] swapBuffers];
//	CC_ENABLE_DEFAULT_GL_STATES();
	
#endif // GAME_AUTOROTATION == kGameAutorotationUIViewController	
}
- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	// Init the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// Try to use CADisplayLink director
	// if it fails (SDK < 3.1) use the default director
	if( ! [CCDirector setDirectorType:kCCDirectorTypeDisplayLink] )
		[CCDirector setDirectorType:kCCDirectorTypeDefault];
	
	
	CCDirector *director = [CCDirector sharedDirector];
	
	// Init the View Controller
	viewController = [[RootViewController alloc] initWithNibName:nil bundle:nil];
	viewController.wantsFullScreenLayout = YES;
	
	//
	// Create the EAGLView manually
	//  1. Create a RGB565 format. Alternative: RGBA8
	//	2. depth format of 0 bit. Use 16 or 24 bit for 3d effects, like CCPageTurnTransition
	//
	//
	EAGLView *glView = [EAGLView viewWithFrame:[window bounds]
								   pixelFormat:kEAGLColorFormatRGB565	// kEAGLColorFormatRGBA8
								   depthFormat:0						// GL_DEPTH_COMPONENT16_OES
						];
	
	// attach the openglView to the director
	[director setOpenGLView:glView];
	
	// Instantiate singleton/load serialized data
	[GameSingleton loadState];
	
	//CCLOG(@"Level property is %i", [GameSingleton sharedGameSingleton].level);
	
	// Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices
	if (![director enableRetinaDisplay:YES])
	{
		CCLOG(@"Retina Display Not supported");
	}
	else
	{
		[GameSingleton sharedGameSingleton].isRetina = YES;
	}
	
	// Set the orientation to be "portrait"
	[director setDeviceOrientation:kCCDeviceOrientationPortrait];
	[director setAnimationInterval:1.0/60];
	[director setDisplayFPS:NO];
	
	// make the OpenGLView a child of the view controller
	[viewController setView:glView];
	
	// make the View Controller a child of the main window
	[window addSubview:viewController.view];
	
	[window makeKeyAndVisible];
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];

	// Load user defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]]];
	
	// Preload some SFX
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"mark.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"fill.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"dud.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"button.caf"];
	
	// Preload music
	[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"1.mp3"];
	[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"2.mp3"];
	[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"tutorial.mp3"];
	[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"win.mp3"];
	[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"lose.mp3"];
	
	// Set BGM volume
	[[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:0.4];
	
	// Removes the startup flicker
	[self removeStartupFlicker];
	
	// Run the intro Scene
	[[CCDirector sharedDirector] runWithScene:[LogoScene scene]];
}


- (void)applicationWillResignActive:(UIApplication *)application {
	[[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[[CCDirector sharedDirector] resume];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCDirector sharedDirector] purgeCachedData];
}

-(void) applicationDidEnterBackground:(UIApplication*)application {
	// Save singleton state
	[GameSingleton saveState];
	
	[[CCDirector sharedDirector] stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
	[[CCDirector sharedDirector] startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Save singleton state
	[GameSingleton saveState];
	
	CCDirector *director = [CCDirector sharedDirector];
	
	[[director openGLView] removeFromSuperview];
	
	[viewController release];
	
	[window release];
	
	[director end];	
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void)dealloc {
	[[CCDirector sharedDirector] end];
	[window release];
	[super dealloc];
}

@end
