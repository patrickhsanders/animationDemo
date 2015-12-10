//
//  ViewController.m
//  AnimatorDemo
//
//  Created by Aditya Narayan on 12/10/15.
//  Copyright © 2015 turntotech.io. All rights reserved.
//

#import "ViewController.h"
#import "Circle.h"
@interface ViewController ()

@property (nonatomic, strong) UIDynamicAnimator *animator;

@property (nonatomic) CGFloat boxSize;

@property (nonatomic, strong) Circle *gameBall;
@property (nonatomic, strong) UIDynamicItemBehavior *gameBallAnimationProperties;

@property (nonatomic, strong) UIView *gamePaddle;
@property (nonatomic, strong) UIDynamicItemBehavior *gamePaddleAnimationProperties;

@property (nonatomic, strong) UIPushBehavior *pusher;

@property (nonatomic, strong) NSMutableArray *borderSquares;

@property (nonatomic, strong) UICollisionBehavior *collision;

@property (nonatomic, strong) NSTimer *borderRecalculationTimer;
@property (nonatomic, strong) NSTimer *blinkingTimer;

@property (strong, nonatomic) IBOutlet UILabel *loseLabel;
@property (strong, nonatomic) IBOutlet UILabel *loseDetail;

@property (nonatomic) BOOL gameActive;
@property (nonatomic) BOOL newGame;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  _newGame = YES;
  
  [self startGame];
  // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)startGame {
  _gameActive = YES;
  _loseDetail.alpha = 0;
  _loseLabel.alpha = 0;
  [_blinkingTimer invalidate];
  
  if(_newGame){
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    _animator.delegate = self;

    //ball object
    _gameBall = [[Circle alloc] initWithFrame:CGRectMake(120,100,20,20)];
    _gameBall.alpha = 0.5;
    _gameBall.layer.cornerRadius = 10;
    _gameBall.backgroundColor = [UIColor blueColor];
    [self.view addSubview:_gameBall];

    
    _gamePaddle = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 50, self.view.bounds.size.height - 50, 100, 20)];
    _gamePaddle.backgroundColor = [UIColor grayColor];
    [self.view addSubview:_gamePaddle];
    
    self.borderSquares = [[NSMutableArray alloc] init];
    [self generateBorderSquares:[UIColor redColor]];
    _newGame = NO;
    
  } else {
    _gameBall.center = CGPointMake(130, 110);
    _gamePaddle.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height - 50);
    for(UIView *borderSquare in _borderSquares){
      borderSquare.alpha = 0;
    }
  }

  //ball animation properties
  _gameBallAnimationProperties = [[UIDynamicItemBehavior alloc] initWithItems:@[_gameBall]];
  _gameBallAnimationProperties.elasticity = 1.0;
  _gameBallAnimationProperties.friction = 0.0;
  _gameBallAnimationProperties.resistance = 0.0;
  [_animator addBehavior:_gameBallAnimationProperties];
  
  //paddle object
  
  //paddle properties
  _gamePaddleAnimationProperties = [[UIDynamicItemBehavior alloc] initWithItems:@[_gamePaddle]];
  _gamePaddleAnimationProperties.allowsRotation = NO;
  _gamePaddleAnimationProperties.density = 1000.0f;
  [_animator addBehavior:_gamePaddleAnimationProperties];
  
  //collision behaviors
  _collision = [[UICollisionBehavior alloc] initWithItems:@[_gameBall, _gamePaddle]];
  _collision.translatesReferenceBoundsIntoBoundary = YES;
  _collision.collisionDelegate = self;
  [self generateBorderBoundaries];
  
  _pusher = [[UIPushBehavior alloc] initWithItems:@[_gameBall] mode:UIPushBehaviorModeInstantaneous];
  _pusher.pushDirection = CGVectorMake(0.5, 1.0);
  _pusher.magnitude = 0.1f;
  _pusher.active = YES;
  
  [self.animator addBehavior:self.pusher];
}

- (void)generateBorderSquares:(UIColor*)color{
  NSLog(@"Squares now: %lu",self.borderSquares.count);
  
  CGFloat alpha = .2;
  CGFloat viewWidth = self.view.bounds.size.width;
  CGFloat viewHeight = self.view.bounds.size.height;
  CGFloat horizontalBoxes = 20;
  CGFloat boxSize = viewWidth / horizontalBoxes;
  _boxSize = boxSize;
  //horizontal borders
  for(int i = 0; i < horizontalBoxes; i++){
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(i*boxSize, 0, boxSize - boxSize / 3, boxSize)];
    view.backgroundColor = color;
    view.alpha = alpha;
    [self.view addSubview:view];
    [self.borderSquares addObject:view];
    
    UIView *view2 = [[UIView alloc] initWithFrame:CGRectMake(i*boxSize, self.view.bounds.size.height-boxSize, boxSize - boxSize / 3, boxSize)];
    view2.backgroundColor = color;
    view2.alpha = alpha;
    [self.view addSubview:view2];
    [self.borderSquares addObject:view2];
  }
  
  //vertical borders
  int numberOfVerticalBoxes = (viewHeight - 2*boxSize) / boxSize;
  float preciseVerticalBoxSize = (viewHeight - 2*boxSize) / numberOfVerticalBoxes;
  
  for (int i = 0; i < numberOfVerticalBoxes ; i ++) {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, boxSize + i*preciseVerticalBoxSize, preciseVerticalBoxSize, preciseVerticalBoxSize - preciseVerticalBoxSize / 3)];
    view.backgroundColor = color;
    view.alpha = alpha;
    [self.view addSubview:view];
    [self.borderSquares addObject:view];
    
    UIView *view2 = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - preciseVerticalBoxSize, boxSize + i*preciseVerticalBoxSize, preciseVerticalBoxSize, preciseVerticalBoxSize - preciseVerticalBoxSize / 3)];
    view2.backgroundColor = color;
    view2.alpha = alpha;
    [self.view addSubview:view2];
    [self.borderSquares addObject:view2];
    [self generateBorderBoundaries];
  }
}

- (void) generateBorderBoundaries{
  //generate boundaries
  CGPoint uL = CGPointMake(_boxSize, _boxSize);
  CGPoint lL = CGPointMake(_boxSize, self.view.bounds.size.height - _boxSize);
  CGPoint uR = CGPointMake(self.view.bounds.size.width - _boxSize, _boxSize);
  CGPoint lR = CGPointMake(self.view.bounds.size.width - _boxSize, self.view.bounds.size.height - _boxSize);
  [_collision addBoundaryWithIdentifier:@"left" fromPoint:uL toPoint:lL];
  [_collision addBoundaryWithIdentifier:@"bottom" fromPoint:lL toPoint:lR];
  [_collision addBoundaryWithIdentifier:@"right" fromPoint:uR toPoint:lR];
  [_collision addBoundaryWithIdentifier:@"top" fromPoint:uL toPoint:uR];
  [_animator addBehavior:_collision];
}

- (void)calculateBallDistanceToBorder{
  UIView *view = _gameBall;
  
  CGFloat alphaGradientDenominator = self.view.bounds.size.width / 2;
  
  for (UIView *borderSquare in _borderSquares){
    CGFloat xDist = (view.center.x - borderSquare.center.x);
    CGFloat yDist = (view.center.y - borderSquare.center.y);
    CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
    if (distance <= alphaGradientDenominator){
      borderSquare.alpha = (alphaGradientDenominator - distance) / alphaGradientDenominator;
    } else {
      borderSquare.alpha = 0;
    }
  }
}


- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
  CGPoint point = [[touches anyObject] locationInView:self.view];
  CGPoint newLocation = CGPointMake(point.x, self.view.bounds.size.height - 50);
  _gamePaddle.center = newLocation;
  [self.animator updateItemUsingCurrentState:_gamePaddle];
}

- (void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
  [self touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
  [self touchesBegan:touches withEvent:event];
  if(_gameActive == NO){
    [self startGame];
  }
}

#pragma mark UIDynamicAnimatorDelegate methods
- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator{
  NSLog(@"animator will resume");
  _borderRecalculationTimer = [NSTimer scheduledTimerWithTimeInterval:.02
                                            target:self selector:@selector(calculateBallDistanceToBorder)
                                          userInfo:nil repeats:YES];
}
- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator{
  NSLog(@"animator will pause");
  [_borderRecalculationTimer invalidate];
}

#pragma mark UICollisonBehaviorDelegate method
- (void)collisionBehavior:(UICollisionBehavior*)behavior beganContactForItem:(id <UIDynamicItem>)item withBoundaryIdentifier:(nullable id <NSCopying>)identifier atPoint:(CGPoint)p{
  
  NSString *string = [NSString stringWithFormat:@"%@",identifier];
  if([string isEqualToString:@"bottom"] && item == _gameBall){
    NSLog(@"You lose");
    _gameActive = NO;
    [_animator removeAllBehaviors];
    _blinkingTimer = [NSTimer scheduledTimerWithTimeInterval:.5
                                                      target:self selector:@selector(blinkBorderSquares)
                                                    userInfo:nil repeats:YES];
  }
}

- (void)blinkBorderSquares{
  float alpha;
  if([_borderSquares[0] alpha] == 1){
    alpha = 0;
  } else {
    alpha = 1;
  }
  
  for (UIView *borderSquare in _borderSquares){
    borderSquare.alpha = alpha;
  }
  _loseLabel.alpha = alpha;
  _loseDetail.alpha = alpha;
}

@end
