//
// Created by lishuo on 13-5-28.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FVDeclaration.h"
#import "NSArray+BlocksKit.h"

@interface FVDeclaration()

@property (nonatomic, strong) NSMutableArray *postProcessBlocks;

@end

@implementation FVDeclaration{
    NSMutableArray *_subDeclarations;
    CGRect _expandedFrame;
    CGRect _unExpandedFrame;
}
@synthesize parent = _parent;

-(id)copyWithZone:(NSZone *)zone
{
    FVDeclaration *dec = [[FVDeclaration alloc] init];
    dec->_name = [_name copy];
    dec->_postProcessBlocks = [_postProcessBlocks copy];
    dec->_object = _object; //Object is shared even in copied declare.

    dec->_expandedFrame = _expandedFrame;
    dec->_unExpandedFrame = _unExpandedFrame;

    dec->_subDeclarations = [NSMutableArray arrayWithCapacity:_subDeclarations.count];
    [_subDeclarations each:^(FVDeclaration* d) {
        [dec appendDeclaration:[d copyWithZone:zone]];
    }];
    return dec;
}

+(FVDeclaration *)declaration:(NSString*)name frame:(CGRect)frame {
    FVDeclaration *declaration = [[FVDeclaration alloc]init];
    declaration->_name = name;
    declaration->_unExpandedFrame = frame;
    declaration->_expandedFrame = frame;
    return declaration;
}

-(FVDeclaration *)assignObject:(UIView*)object{
    _object = object;
    return self;
}

-(FVDeclaration *)withDeclarations:(NSArray *)array{
    _subDeclarations = [array mutableCopy];
    [_subDeclarations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((FVDeclaration *)obj)->_parent = self;
    }];
    return self;
}

-(NSArray *)subDeclarations {
    return _subDeclarations;
}

-(FVDeclaration *)declarationByName:(NSString *)name {
    if([_name isEqualToString:name]) {
        return self;
    }
    else{
        for(FVDeclaration *declaration in _subDeclarations){
            FVDeclaration *dec = [declaration declarationByName:name];
            if(dec != nil){
                return dec;
            }
        }
    }

    return nil;
}

-(void)calculateLayout {
    // add sub declarations to refresh their parent node
    [self withDeclarations:_subDeclarations];

    if(![self calculated:NO]){
        [self calculateX];
        [self calculateWidth];
        [self calculateY];
        [self calculateHeight];
    }

    for(FVDeclaration *declaration in _subDeclarations){
        [declaration calculateLayout];
    }
}

- (void)calculateHeight {
    CGFloat h = _expandedFrame.size.height;
    if (!FVIsNormal(h)){
        if (FVIsPercent(h)){
            if (_parent && _parent.heightCalculated){
                [self assignHeight: _parent->_expandedFrame.size.height * FVF2P(h)];
            }
        }
        else if(FVIsRelated(h)){
            NSAssert(_parent, @"%@ FVRelated: parent is nil", _name);
            FVDeclaration *prev = [_parent prevSiblingOfChild:self];
            if(prev){
                if (prev.heightCalculated) {
                    [self assignHeight: prev->_expandedFrame.size.height + FVF2R(h)];
                }
                //In order to prevent deadloop, the calculation order is top down, left right rule,
                //if prev height not calculated, wait next time
            }
            else{
                [self assignHeight:FVF2R(h)];
            }
        }
        else if (FVIsTail(h)){
            NSAssert(_parent, @"%@ FVTail must has a valid parent, and its height already calcualted", _name);
            if(_parent.heightCalculated){
                [self assignHeight:_parent->_expandedFrame.size.height - FVFloat2Tail(h)];
            }
        }
        else if(FVIsFill(h)){
            NSAssert(_parent, @"%@ FVFill: parent is nil", _name);
            FVDeclaration *next = [_parent nextSiblingOfChild:self];
            if (next) {
                if(!next.yCalculated){
                    [next calculateLayout];
                }
                if(next.yCalculated){
                    [self assignHeight: next->_expandedFrame.origin.y - _expandedFrame.origin.y];
                }
            }
            else{
                [self assignHeight:_parent->_expandedFrame.size.height - _expandedFrame.origin.y];
            }
        }
        else if(FVIsAuto(h)){
            if (_subDeclarations && _subDeclarations.count > 0){
                CGFloat height = 0.0f;
                for(FVDeclaration *declaration in _subDeclarations){
                    [declaration calculateLayout];
                    NSAssert(declaration.yCalculated && declaration.heightCalculated, @"%@ FVAuto: y and height must calculated", _name);
                    CGFloat bottom = declaration.frame.origin.y + declaration.frame.size.height;
                    height = height > bottom ? height : bottom;
                }
                [self assignHeight:height];
            }
            else{
                [self assignHeight:0];
            }
        }
        else if (FVIsTillEnd(h)){
            NSAssert(_parent && _parent.heightCalculated, @"%@ Height TillEnd requires a valid parent and its height already calculated", _name);
            NSAssert(self.yCalculated, @"%@ Height TillEnd requires y calculated", _name);
            [self assignHeight:_parent->_expandedFrame.size.height - _expandedFrame.origin.y];
        }
        else{
            NSAssert(NO, @"%@ Code should not hit this place", _name);
        }
    }
}

- (void)calculateY {
    CGFloat y = _expandedFrame.origin.y;
    if(!FVIsNormal(y)){
        if(FVIsPercent(y)){
            NSAssert(_parent, @"%@ Percent y: must have a parent", _name);
            if(_parent.heightCalculated){
                [self assignY:_parent.frame.size.height * FVF2P(y)];
            }
        }
        else if(FVIsAfter(y)){
            NSAssert(_parent, @"%@ FVAfter must has a valid parent", _name);
            FVDeclaration *prev = [_parent prevSiblingOfChild:self];
            if(prev){
                if(prev.yCalculated && prev.heightCalculated){
                    [self assignY: prev.frame.origin.y + prev.frame.size.height + FVFloat2After(y)];
                }
            }
            else{
                [self assignY:FVFloat2After(y)];
            }
        }
        else if(FVIsTail(y)){
            if(_parent && _parent.heightCalculated){
                [self assignY:_parent.frame.size.height - FVF2T(y)];
            }
        }
        else if(FVIsRelated(y)){
            if(_parent){
                FVDeclaration *prev = [_parent prevSiblingOfChild:self];
                if(prev && prev.yCalculated){
                    [self assignY: prev.frame.origin.y + FVF2R(y)];
                }
                else{
                    [self assignY:FVF2R(y)];
                }
            }
        }
        else if (FVIsCenter(y)){
            NSAssert(_parent && _parent.heightCalculated, @"%@ FVCenter must has a valid parent", _name);
            if(!self.heightCalculated){
                [self calculateHeight];
            }
            NSAssert(self.heightCalculated, @"%@ Height must be calcuated for FVCenter Y", _name);
            [self assignY:(_parent.frame.size.height - _expandedFrame.size.height)/2];
        }
        else if (FVIsAutoTail(y)){
            NSAssert(_parent && _parent.heightCalculated, @"%@ FVAutoTail must has a vlid parent and height been calculated", _name);
            if(!self.heightCalculated){
                [self calculateHeight];
            }
            NSAssert(self.heightCalculated, @"%@ Height must be calculated for FVAutoTail Y", _name);
            [self assignY:(_parent.frame.size.height - _expandedFrame.size.height)];
        }
    }
}

- (void)calculateWidth {
    CGFloat w = _expandedFrame.size.width;
    if(!FVIsNormal(w)){
        if(FVIsPercent(w)){
            if(_parent && _parent.widthCalculated){
                [self assignWidth: _parent.frame.size.width * FVF2P(w)];
            }
        }
        else if (FVIsRelated(w)){
            FVDeclaration *prev = [self prevSibling];
            if(prev && prev.widthCalculated){
                [self assignWidth:prev.frame.size.width + FVF2R(w)];
            }
            else{
                [self assignWidth:FVF2R(w)];
            }
        }
        else if (FVIsTail(w)){
            NSAssert(_parent, @"%@ FVTail on width must has a valid parent", _name);
            if(_parent.widthCalculated){
                [self assignWidth:_parent.frame.size.width - FVF2T(w)];
            }
        }
        else if(FVIsFill(w)){
            //Need the next x's x been calculated
            FVDeclaration *next = [self nextSibling];
            if (next) {
                if(!next.xCalculated){
                    [next calculateLayout];
                }

                if(next.xCalculated){
                    [self assignWidth:next.frame.origin.x - _expandedFrame.origin.x];
                }
            }
            else{
                [self assignWidth:_parent.frame.size.width - _expandedFrame.origin.x];
            }
        }
        else if(FVIsAuto(w)){
            if(_subDeclarations && _subDeclarations.count > 0){
                CGFloat width = 0.0f;
                for( FVDeclaration *declaration in _subDeclarations){
                    if(!declaration.xCalculated || !declaration.widthCalculated){
                        [declaration calculateLayout];
                    }
                    NSAssert(declaration.xCalculated && declaration.widthCalculated, @"%@ Auto for w: sub declaration's x and width must be calculated", _name);
                    CGFloat right = declaration.frame.origin.x + declaration.frame.size.width;
                    width = width > right ? width : right;
                }
                [self assignWidth:width];
            }
            else{
                [self assignWidth:0];
            }
        }
        else if (FVIsTillEnd(w)){
            NSAssert(_parent && _parent.widthCalculated, @"%@ TillEnd requires a valid parent and its width calculated", _name);
            NSAssert(self.xCalculated, @"%@ TillEnd requires x already calculated", _name);
            [self assignWidth:_parent->_expandedFrame.size.width - _expandedFrame.origin.x];
        }
    }
}

- (void)calculateX {
    CGFloat x = _expandedFrame.origin.x;
    if(!FVIsNormal(x)){
        if(FVIsPercent(x)){
            NSAssert(_parent, @"%@ For percent values, the parent must not be nil", _name);
            if(_parent.widthCalculated){
                _expandedFrame.origin.x = _parent.expandedFrame.size.width * FVF2P(x);
            }
        }
        else if(FVIsFill(x)){
            NSAssert(!FVIsFill(x), @"%@ x not support FVFill", _name);
        }
        else if(FVIsAfter(x)){
            NSAssert(_parent, @"%@ FVAfter must has a valid parent", _name);
            FVDeclaration *prev = [_parent prevSiblingOfChild:self];
            if(prev){
                if(prev.xCalculated && prev.widthCalculated){
                    [self assignX: prev.frame.origin.x + prev.frame.size.width + FVFloat2After(x)];
                }
            }
            else{
                [self assignX:FVFloat2After(x)];
            }
        }
        else if(FVIsTail(x)){
            NSAssert(_parent, @"%@ FVTail on x must has a valid parent", _name);
            if(_parent.widthCalculated){
                [self assignX: _parent.frame.size.width - FVF2T(x)];
            }
        }
        else if(FVIsRelated(x)){
            NSAssert(_parent, @"%@ FVRelated must has a valid parent", _name);
            FVDeclaration *prev = [_parent prevSiblingOfChild:self];
            if(prev && prev.xCalculated){
                [self assignX: prev.frame.origin.x + FVF2R(x)];
            }
            else{
                [self assignX:FVF2R(x)];
            }
        }
        else if(FVIsCenter(x) || FVIsAutoTail(x)){
            NSAssert(_parent && _parent.widthCalculated, @"%@ FVCenter or FVAutoTail must has a valid parent and width calcluated", _name);
            //note: caution, if width needs x, and x needs width, dead lock occur
            if(![self widthCalculated]){
                [self calculateWidth];
            }
            NSAssert([self widthCalculated], @"%@ the width should be calcualted when FVCenter specified", _name);

            if(FVIsCenter(x)){
                [self assignX: (_parent.frame.size.width - _expandedFrame.size.width)/2 ];
            }
            else if(FVIsAutoTail(x)){
                [self assignX:(_parent.frame.size.width - _expandedFrame.size.width)];
            }
        }
    }
}

-(FVDeclaration *)nextSiblingOfChild:(FVDeclaration *)declaration{
    NSUInteger index = [_subDeclarations indexOfObject:declaration];
    if(index != NSNotFound && index + 1 < _subDeclarations.count){
        return _subDeclarations[index+1];
    }
    return nil;
}

-(FVDeclaration *)prevSiblingOfChild:(FVDeclaration *)declaration{
    NSUInteger index = [_subDeclarations indexOfObject:declaration];
    if(index != NSNotFound && index > 0){
        return _subDeclarations[index-1];
    }
    return nil;
}

-(FVDeclaration *)prevSibling{
    if(_parent){
        return [_parent prevSiblingOfChild:self];
    }
    return nil;
}

-(FVDeclaration *)nextSibling{
    if(_parent){
        return [_parent nextSiblingOfChild:self];
    }
    return nil;
}

-(void)assignWidth:(CGFloat)width{
    _expandedFrame.size.width = width;
}

-(void)assignX:(CGFloat)x{
    _expandedFrame.origin.x = x;
}

-(void)assignY:(CGFloat)y{
    CGRect frame = _expandedFrame;
    frame.origin.y = y;
    _expandedFrame = frame;
}

-(void)assignHeight:(CGFloat)height{
    CGRect frame = _expandedFrame;
    frame.size.height = height;
    _expandedFrame = frame;
}


-(BOOL)calculated:(BOOL)recursive {
    if (!FVIsNormal(_expandedFrame.origin.x) || !FVIsNormal(_expandedFrame.origin.y) || !FVIsNormal(_expandedFrame.size.width) || !FVIsNormal(_expandedFrame.size.height)){
        return NO;
    }
    if(recursive){
        for(FVDeclaration *declaration in _subDeclarations){
            if(![declaration calculated:recursive]){
                return NO;
            }
        }
    }

    return YES;
}

-(void)setupViewTree{
    [self setupViewTreeInto:nil];
}

-(void)setupViewTreeInto:(UIView *)superView{
    if(superView != nil && _object != nil){
        [_object removeFromSuperview];
        [superView addSubview:_object];
    }

    UIView *subviewAddIntoView = superView;
    if (_object != nil){
        subviewAddIntoView = _object;
    }

    for(FVDeclaration *declaration in _subDeclarations){
        [declaration setupViewTreeInto:subviewAddIntoView];
    }
}

-(void)updateViewFrame{
    //Find this node's offset frame
    CGPoint offsetPoint = CGPointZero;
    FVDeclaration *dec = _parent;
    while(dec && dec.object == nil){
        NSAssert([dec calculated:NO], @"%@ The parent's layout has to be calculated when call updateView frame in sub declaration", _name);
        offsetPoint.x += dec.expandedFrame.origin.x;
        offsetPoint.y += dec.expandedFrame.origin.y;
        dec = dec.parent;
    }

    [self updateViewFrameInternalWithOffsetFrame:CGRectMake(offsetPoint.x, offsetPoint.y, 0, 0)];
}

-(void)updateViewFrameInternalWithOffsetFrame:(CGRect)offsetFrame{
    if (![self calculated:NO]){
        [self calculateLayout];
    }

    CGRect myFrame = CGRectOffset(_expandedFrame, offsetFrame.origin.x, offsetFrame.origin.y);

    if(_object != nil && !CGRectEqualToRect(_object.frame, myFrame)){
        _object.frame = myFrame;
    }

    CGRect subviewBaseOnFrame = myFrame;
    if (_object != nil){
        subviewBaseOnFrame = CGRectZero;
    }
    for(FVDeclaration *declaration in _subDeclarations){
        [declaration updateViewFrameInternalWithOffsetFrame:subviewBaseOnFrame];
    }

    for(FVDeclarationProcessBlock block in _postProcessBlocks){
        block(self);
    }
}

-(FVDeclaration *)assignUnExpandedFrame:(CGRect)frame{
    [self setUnExpandedFrame:frame];
    _expandedFrame = _unExpandedFrame;
    return self;
}

-(CGRect)frame{
    return _expandedFrame;
}

-(void)setFrame:(CGRect)frame{
    _unExpandedFrame = frame;
    _expandedFrame = _unExpandedFrame;
}

-(CGRect)expandedFrame{
    return _expandedFrame;
}

-(void)setUnExpandedFrame:(CGRect)unExpandedFrame {
    _unExpandedFrame = unExpandedFrame;
    _expandedFrame = unExpandedFrame;
}
-(CGRect)unExpandedFrame {
    return _unExpandedFrame;
}

-(FVDeclaration *)process:(FVDeclarationProcessBlock)processBlock {
    processBlock(self);
    return self;
}

-(void)resetLayout {
    [self resetLayoutWithDepth:INT32_MAX];
}

-(void)resetLayoutWithDepth:(int)depth {
    if (depth <= 0){
        return;
    }
    else if(depth >= 1){
        // restore the frame to the original one, doing this will discard all the changes made
        // So in order to update the frame, one should call reset layout first, then set new frame
        _expandedFrame = _unExpandedFrame;

        if(depth > 1){
            for (FVDeclaration *declaration in _subDeclarations){
                [declaration resetLayoutWithDepth:depth-1];
            }
        }
    }
}

-(FVDeclaration *)appendDeclaration:(FVDeclaration *)declaration {
    if(_subDeclarations == nil){
        _subDeclarations = [NSMutableArray array];
    }
    [_subDeclarations addObject:declaration];
    declaration->_parent = self;

    return self;
}

-(void)removeDeclaration:(FVDeclaration*)declaration{
    [_subDeclarations removeObject:declaration];
    declaration->_parent = nil;
}

-(void)removeFromParentDeclaration {
    [_parent removeDeclaration:self];
}

- (FVDeclaration *)postProcess:(FVDeclarationProcessBlock)processBlock {
    if(_postProcessBlocks == nil){
        _postProcessBlocks = [NSMutableArray array];
    }
    [_postProcessBlocks addObject:[processBlock copy]];
    return self;
}

-(UIView *)superView{
    FVDeclaration *d = _parent;
    while(d != nil && d.object == nil){
        d = d->_parent;
    }

    if(d == nil){
        return nil;
    }
    return d.object;
}

-(BOOL)xCalculated {
    return FVIsNormal(_expandedFrame.origin.x);
}

-(BOOL)yCalculated {
    return FVIsNormal(_expandedFrame.origin.y);
}

-(BOOL)widthCalculated {
    return FVIsNormal(_expandedFrame.size.width);
}

-(BOOL)heightCalculated {
    return FVIsNormal(_expandedFrame.size.height);
}
@end
