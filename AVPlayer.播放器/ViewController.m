//
//  ViewController.m
//  AVPlayer.播放器
//
//  Created by mac on 16/5/31.
//  Copyright © 2016年 Cijian.Wu. All rights reserved.
//

#import "ViewController.h"
#import "CJPlayer.h"
#import <AVFoundation/AVFoundation.h>

#define PATH @"/Users/qianfeng/Desktop/asd"


@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UISlider *sliderView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;


@property(nonatomic,strong)AVPlayer *player;
@property(nonatomic,strong)AVPlayerItem *item;

@property(nonatomic,strong)NSMutableArray *musicArrM;
@property(nonatomic,strong)NSMutableArray *lyricsArrM;
@property(nonatomic,strong)NSMutableArray *lyricsTimeArrM;
@property(nonatomic,strong)NSMutableArray *lyricsStrArrM;

@property(nonatomic,assign)NSInteger currentMusic;
@property(nonatomic,assign)NSInteger currentLine;

@property(nonatomic,assign)CMTime time;

@property(nonatomic,strong)NSTimer *timer;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self loadData];
    [self loadPlayer];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
}

-(void)loadPlayer
{
    self.item = nil;
    self.player = nil;
    
    self.item = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:self.musicArrM[self.currentMusic] ofType:nil]]];
    self.player = [AVPlayer playerWithPlayerItem:self.item];
    CJPlayer *player = [[CJPlayer alloc] initWithFrame:self.view.bounds];
    ((AVPlayerLayer*)player.layer).player = self.player;
    
    [self.view addSubview:player];
    [self.view sendSubviewToBack:player];
    
    [self.item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self loadLyrics:self.currentMusic];
    self.currentLine = 0;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
}

-(void)loadData
{
    self.musicArrM = [NSMutableArray array];
    self.lyricsArrM = [NSMutableArray array];
    if (_musicArrM.count == 0) {
        _musicArrM = [NSMutableArray array];
        NSArray *fileArr = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:PATH error:nil];
        for (NSString *str in fileArr) {
            if ([[str pathExtension] isEqualToString:@"mp3"]) {
                [self.musicArrM addObject:str];
            }
            if ([[str pathExtension] isEqualToString:@"lrc"]) {
                [self.lyricsArrM addObject:str];
            }
        }
    }
}

-(void)loadLyrics:(NSInteger)index
{
    self.lyricsStrArrM = [NSMutableArray array];
    self.lyricsTimeArrM = [NSMutableArray array];
    NSString *string = [NSString stringWithContentsOfFile:[PATH stringByAppendingFormat:@"/%@",self.lyricsArrM[index]] encoding:NSUTF8StringEncoding error:nil];
    NSArray *arr = [string componentsSeparatedByString:@"["];
    for (NSString *str in arr) {
        NSArray *array = [str componentsSeparatedByString:@"]"];
        if (!([array[0] isEqualToString:@""] || [array[1] isEqualToString:@"\n"] || [array[1] isEqualToString:@"\r\n"])) {
            [self.lyricsStrArrM addObject:array[1]];
            [self.lyricsTimeArrM addObject:array[0]];
        }
    }
}

-(void)timerAction:(NSTimer *)timer
{
    self.sliderView.value = self.player.currentTime.value /self.player.currentTime.timescale;
    
    for (int i = 0 ; i < self.lyricsStrArrM.count; i++) {
        NSArray *timeArr = [self.lyricsTimeArrM[self.currentLine] componentsSeparatedByString:@":"];
        CGFloat time = [timeArr[0] floatValue] * 60 + [timeArr[1] floatValue];
        if (time  < self.sliderView.value) {
            self.currentLine = i ;
        }else
        {
            break;
        }
    }
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentLine inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    AVPlayerItemStatus itemStatus = [change[NSKeyValueChangeNewKey] integerValue];
    if (itemStatus == AVPlayerItemStatusReadyToPlay) {
        self.sliderView.maximumValue = self.item.duration.value / self.item.duration.timescale;
        self.time = self.item.duration;
        
        __weak UISlider *slider = self.sliderView;
        
        [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0f, 1.0f) queue:nil usingBlock:^(CMTime time) {
            slider.value = time.value/time.timescale;
        }];
        
    }
}
- (IBAction)sliderAction:(UISlider *)sender {
    [self.player seekToTime:CMTimeMake(sender.value *self.time.timescale, self.time.timescale)];
}
- (IBAction)statusControlClick:(UIButton *)sender {
    if (!sender.selected) {
        [self.player play];
         self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
    }else
    {
        [self.player pause];
        [self.timer invalidate];
    }
    sender.selected = !sender.selected;
}
- (IBAction)prevAction {
    [self.player pause];
    [self.timer invalidate];
    self.currentMusic --;
    if (self.currentMusic == -1) {
        self.currentMusic = self.musicArrM.count -1;
    }
    [self loadPlayer];
    [self.player play];
   
}
- (IBAction)nextAction {
    [self.player pause];
    [self.timer invalidate];
    self.currentMusic ++;
    if (self.currentMusic == self.musicArrM.count) {
        self.currentMusic = 0;
    }
    [self loadPlayer];
    [self.player play];
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.lyricsStrArrM.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    cell.textLabel.text = self.lyricsStrArrM[indexPath.row];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    if (self.currentLine -1 == indexPath.row) {
        cell.textLabel.textColor = [UIColor purpleColor];
    }else
    {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
