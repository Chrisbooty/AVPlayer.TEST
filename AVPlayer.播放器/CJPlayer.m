//
//  CJPlayer.m
//  AVPlayer.播放器
//
//  Created by mac on 16/5/31.
//  Copyright © 2016年 Cijian.Wu. All rights reserved.
//

#import "CJPlayer.h"
#import <AVFoundation/AVFoundation.h>

@implementation CJPlayer

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+(Class)layerClass
{
    return [AVPlayerLayer class];
}

@end
