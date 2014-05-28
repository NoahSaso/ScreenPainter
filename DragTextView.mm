#import "DragTextView.h"

#define kScreenSize [UIScreen mainScreen].bounds

@implementation DragTextView

static float tappedSpotX, tappedSpotY = 0;
static BOOL didMove = NO;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.superview bringSubviewToFront:self];
	[self.superview becomeFirstResponder];
	//Get touch instance
	UITouch *touch = [touches anyObject];
	CGPoint touchLocation = [touch locationInView:self];
	//Set the tappedSpot so I know how much to move it
	tappedSpotX = touchLocation.x;
	tappedSpotY = touchLocation.y;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	didMove = YES;
	//Define touch variables
	UITouch *touch = [touches anyObject];
	//Get touch location
	CGPoint touchLocation = [touch locationInView:self.superview];
	
	CGPoint touchInSelf = [touch locationInView:self];
	CGFloat tx = touchInSelf.x;
	CGFloat ty = touchInSelf.y;

	if(tx>=self.frame.size.width-30&&ty>=self.frame.size.height-30) {

		//Restrict size
		if(tx<=50) tx = 50;
		if(ty<=50) ty = 50;

		//Modify frame to size
		CGRect frame = self.frame;
		frame.size.width = tx;
		frame.size.height = ty;
		[self setFrame:frame];

	} else {

		//Change frame so it moves
		CGRect frame = self.frame;
		CGFloat newOriginX = touchLocation.x - tappedSpotX;
		CGFloat newOriginY = touchLocation.y - tappedSpotY;

		//Make sure frame is in bounds
		if((newOriginX + frame.size.width)<=kScreenSize.size.width){
			frame.origin.x = newOriginX;
		}
		if((newOriginY + frame.size.height)<=kScreenSize.size.height){
			frame.origin.y = newOriginY;
		}
		if(newOriginX<=0) frame.origin.x = 0;
		if(newOriginY<=0) frame.origin.y = 0;

		//Set frame
		[self setFrame:frame];

	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if(!didMove){
		[self becomeFirstResponder];
	}else{
		[self.superview becomeFirstResponder];
	}
	didMove = NO;
}

@end