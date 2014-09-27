//
//  ViewController.m
//  spritybird
//
//  Created by Alexis Creuzot on 09/02/2014.
//  Copyright (c) 2014 Alexis Creuzot. All rights reserved.
//

#import "ViewController.h"
#import "Scene.h"
#import "Score.h"

@interface ViewController ()
@property (weak,nonatomic) IBOutlet SKView * gameView;
@property (weak,nonatomic) IBOutlet UIView * getReadyView;

@property (weak,nonatomic) IBOutlet UIView * gameOverView;
@property (weak,nonatomic) IBOutlet UIImageView * medalImageView;
@property (weak,nonatomic) IBOutlet UILabel * currentScore;
@property (weak,nonatomic) IBOutlet UILabel * bestScoreLabel;

@end

@implementation ViewController
{
    Scene * scene;
    UIView * flash;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.df1Manager = [[DF1Manager alloc] initWithDelegate:self];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
	// Configure the view.
    //self.gameView.showsFPS = YES;
    //self.gameView.showsNodeCount = YES;
    
    // Create and configure the scene.
    scene = [Scene sceneWithSize:self.gameView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    scene.delegate = self;
    
    // Present the scene
    self.gameOverView.alpha = 0;
    self.gameOverView.transform = CGAffineTransformMakeScale(.9, .9);
    [self.gameView presentScene:scene];
    
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Bouncing scene delegate

- (void)eventStart
{
    [UIView animateWithDuration:.2 animations:^{
        self.gameOverView.alpha = 0;
        self.gameOverView.transform = CGAffineTransformMakeScale(.8, .8);
        flash.alpha = 0;
        self.getReadyView.alpha = 1;
    } completion:^(BOOL finished) {
        [flash removeFromSuperview];

    }];
}

- (void)eventPlay
{
    [UIView animateWithDuration:.5 animations:^{
        self.getReadyView.alpha = 0;
    }];
}

- (void)eventWasted
{
    flash = [[UIView alloc] initWithFrame:self.view.frame];
    flash.backgroundColor = [UIColor whiteColor];
    flash.alpha = .9;
    [self.gameView insertSubview:flash belowSubview:self.getReadyView];
    
    [self shakeFrame];
    
    [UIView animateWithDuration:.6 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        // Display game over
        flash.alpha = .4;
        self.gameOverView.alpha = 1;
        self.gameOverView.transform = CGAffineTransformMakeScale(1, 1);
        
        // Set medal
        if(scene.score >= 40){
            self.medalImageView.image = [UIImage imageNamed:@"medal_platinum"];
        }else if (scene.score >= 30){
            self.medalImageView.image = [UIImage imageNamed:@"medal_gold"];
        }else if (scene.score >= 20){
            self.medalImageView.image = [UIImage imageNamed:@"medal_silver"];
        }else if (scene.score >= 10){
            self.medalImageView.image = [UIImage imageNamed:@"medal_bronze"];
        }else{
            self.medalImageView.image = nil;
        }
        
        // Set scores
        self.currentScore.text = F(@"%li",scene.score);
        self.bestScoreLabel.text = F(@"%li",(long)[Score bestScore]);
        
    } completion:^(BOOL finished) {
        flash.userInteractionEnabled = NO;
    }];
    
}

- (void) shakeFrame
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.05];
    [animation setRepeatCount:4];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake([self.view  center].x - 4.0f, [self.view  center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake([self.view  center].x + 4.0f, [self.view  center].y)]];
    [[self.view layer] addAnimation:animation forKey:@"position"];
}

- (void)df1Manager:(DF1Manager *)manager didChangeState:(CBCentralManagerState)state
{
    if (state == CBCentralManagerStatePoweredOn) {
        [self.df1Manager startScan];
    }
}

- (void)df1Manager:(DF1Manager *)manager didDiscover:(DF1 *)df1
{
    if (![@"2916E8EE-9355-0A8A-1FFC-08CAEB19D201" isEqualToString:df1.uuid] && ![@"3C597EEF-B63E-4A91-36D7-908C1D9EEB52" isEqualToString:df1.uuid]) {
        return;
    }
    
    [self.df1Manager stopScan];
    
    self.df1 = df1;
    
    self.df1.delegate = self;
    
    [self.df1Manager connect:self.df1];
}

- (void)df1Manager:(DF1Manager *)manager didConnect:(DF1 *)df1
{
    [self.df1 setup];
}

- (void)df1Manager:(DF1Manager *)manager didDisconnect:(DF1 *)df1
{
    
}

- (void)df1DidSetup:(DF1 *)df1
{
    NSLog(@"df1DidSetup");
}

- (void)df1:(DF1 *)df1 didUpdateX:(float)x y:(float)y z:(float)z
{
    static float oldZ = 1;
    static float oldDeltaZ = 0;
    
    static float peakZ = 1;
    
    float deltaZ = (oldZ - z);

    if (deltaZ > 0 && oldDeltaZ < 0) {
        NSLog(@"was going down, now going up");
        
        float deltaFlap = (peakZ - z);
        
        if (deltaFlap > 0.4) {
            NSLog(@"FLAP!");
            
            [scene flapDetected:40];
        }
        
    } else if (deltaZ < 0 && oldDeltaZ > 0) {
        NSLog(@"was going up, now going down");
        peakZ = z;
    }
    
    
    oldZ = z;
    oldDeltaZ = deltaZ;
    
    
//    static float oldZ = 0;
//    static float oldDeltaZ = 0;
//    
//    float deltaZ = (oldZ - z);
//    
//    if (fabsf(deltaZ) < 0.05) {
//        return;
//    }
//
////        NSLog(@"%f", z);
//    
//    NSLog(@"%f", deltaZ);
//    
//    if (oldDeltaZ > 0 && deltaZ < 0) {
//        NSLog(@"FLAPPPPP");
//        
//        [scene flapDetected];
//    }
//    
//    oldZ = z;
//    
//    oldDeltaZ = deltaZ;
}

@end
