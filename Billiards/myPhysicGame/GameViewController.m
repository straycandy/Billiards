//
//  GameViewController.m
//  myPhysicGame
//
//  Created by mengran on 2018/9/28.
//  Copyright © 2018年 ggV5. All rights reserved.
//

#import "GameViewController.h"
#import "GameScene.h"

@interface GameViewController()
@property (nonatomic, strong) SKView        *gameSKView;
@end

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.gameSKView];
    
    // Load the SKScene from 'GameScene.sks'
    GameScene *scene = [[GameScene alloc]initWithSize:CGSizeMake(kScreenWidth, kScreenHeight)];
    
    // Present the scene
    [self.gameSKView presentScene:scene];
    
    self.gameSKView.showsFPS = YES;
    self.gameSKView.showsNodeCount = YES;
    
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (SKView *)gameSKView{
    if (!_gameSKView) {
        _gameSKView = [[SKView alloc]initWithFrame:self.view.bounds];
    }
    return _gameSKView;
}

@end
