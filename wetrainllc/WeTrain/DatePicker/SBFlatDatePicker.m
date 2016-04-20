//
//  SBFlatDatePicker.m
//  SBFlatDatePicker
//
//  Created by Solomon Bier on 2/19/15.
//  Copyright (c) 2015 Solomon Bier. All rights reserved.
//

#import "SBFlatDatePicker.h"
#import "SBFlatDatePickerDelegate.h"
#import "NSString+ValidateEmail.h"
#import "WeTrain-Swift.h"



//Check screen macros
#define IS_WIDESCREEN (fabs ( (double)[[UIScreen mainScreen] bounds].size.height - (double)568) < DBL_EPSILON)
#define IS_OS_6_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0 )
#define IS_OS_7_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)


//Editable macros
//#define TEXT_COLOR [UIColor colorWithWhite:0.5 alpha:1.0]
//#define SELECTED_TEXT_COLOR [UIColor whiteColor]
//#define LINE_COLOR [UIColor colorWithWhite:0.80 alpha:1.0]

#define TEXT_COLOR [UIColor blackColor]
#define SELECTED_TEXT_COLOR [UIColor colorWithRed:83/255.0 green:221/255.0 blue:159/255.0 alpha:1.0]
#define LINE_COLOR [UIColor colorWithRed:.431 green:.431 blue:.431 alpha:1.0]


#define SAVE_AREA_COLOR [UIColor colorWithRed:14/255.0 green:221.0/255.0 blue:161/255.0 alpha:1.0]
#define BAR_SEL_COLOR   [UIColor colorWithRed:14/255.0 green:221.0/255.0 blue:161/255.0 alpha:1.0]
//#define SAVE_BUTTON_COLOR [UIColor colorWithRed:.45 green:.76 blue:.19 alpha:1.0]
#define SAVE_BUTTON_COLOR [UIColor colorWithRed:14/255.0 green:221.0/255.0 blue:161/255.0 alpha:1.0]
//#define SAVE_AREA_COLOR [UIColor colorWithRed:.69 green:.214 blue:.135 alpha:1.0]

//Editable constants
static const float VALUE_HEIGHT = 80.0;
static const float SAVE_AREA_HEIGHT = 50.0;
static const float SAVE_AREA_MARGIN_TOP = 20.0;


//Editable values
float PICKER_HEIGHT = 600;
NSString *FONT_NAME = @"Helvetica";
NSString *BOLD_FONT_NAME = @"Helvetica-Bold";

NSString *NOW = @"Now";

//Static macros and constants
#define SELECTOR_ORIGIN (PICKER_HEIGHT/2.0-VALUE_HEIGHT/2.0)
#define SAVE_AREA_ORIGIN_Y self.bounds.size.height-SAVE_AREA_HEIGHT
#define PICKER_ORIGIN_Y SAVE_AREA_ORIGIN_Y-SAVE_AREA_MARGIN_TOP-PICKER_HEIGHT
#define BAR_SEL_ORIGIN_Y PICKER_HEIGHT/2.0-VALUE_HEIGHT/2.0


//Custom UIButton
@implementation SBPickerButton

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        //[self setBackgroundColor:SAVE_BUTTON_COLOR];
        [self setBackgroundImage:[UIImage imageNamed:@"trainerButtonBg"] forState:UIControlStateNormal];
        [self setBackgroundImage:[UIImage imageNamed:@"trainerButtonSelBg"] forState:UIControlStateHighlighted];

        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:15.0]];
        
        self.clipsToBounds = YES;
        
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    CGFloat outerMargin = 5.0f;
//    CGRect outerRect = CGRectInset(self.bounds, outerMargin, outerMargin);
//    CGFloat radius = 6.0;
//
//    CGMutablePathRef outerPath = CGPathCreateMutable();
//    CGPathMoveToPoint(outerPath, NULL, CGRectGetMidX(outerRect), CGRectGetMinY(outerRect));
//    CGPathAddArcToPoint(outerPath, NULL, CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect), radius);
//    CGPathAddArcToPoint(outerPath, NULL, CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect), radius);
//    CGPathAddArcToPoint(outerPath, NULL, CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMinY(outerRect), radius);
//    CGPathAddArcToPoint(outerPath, NULL, CGRectGetMinX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect), radius);
//    CGPathCloseSubpath(outerPath);
//    
//    CGContextSaveGState(context);
//    CGContextSetStrokeColorWithColor(context, (self.state != UIControlStateHighlighted) ? SAVE_BUTTON_COLOR.CGColor : SELECTED_TEXT_COLOR.CGColor);
//    CGContextAddPath(context, outerPath);
//    CGContextStrokePath(context);
//    CGContextRestoreGState(context);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self setNeedsDisplay];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self setNeedsDisplay];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    [self setNeedsDisplay];
}

@end

//Custom scrollView
@interface SBPickerScrollView ()
@property (nonatomic, strong) NSArray *arrValues;
@property (nonatomic, strong) UIFont *cellFont;
@property (nonatomic, strong) UIFont *boldCellFont;
@property (nonatomic, assign, getter = isScrolling) BOOL scrolling;

@end

@implementation SBPickerScrollView

//Constants
const float LBL_BORDER_OFFSET = 8.0;

//Configure the tableView
- (id)initWithFrame:(CGRect)frame andValues:(NSArray *)arrayValues
      withTextAlign:(NSTextAlignment)align andTextSize:(float)txtSize {
    
    if(self = [super initWithFrame:frame]) {
        [self setScrollEnabled:YES];
        [self setShowsVerticalScrollIndicator:NO];
        [self setUserInteractionEnabled:YES];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [self setContentInset:UIEdgeInsetsMake(BAR_SEL_ORIGIN_Y, 0.0, BAR_SEL_ORIGIN_Y, 0.0)];
        
        _cellFont = [UIFont fontWithName:FONT_NAME size:19];
        _boldCellFont = [UIFont fontWithName:BOLD_FONT_NAME size:19];

        if(arrayValues)
            _arrValues = [arrayValues copy];
    }
    return self;
}


//Dehighlight the last cell
- (void)dehighlightLastCell {
    
    NSLog(@"_tagLastSelected  %d  _arrValuescount  %d",_tagLastSelected,_arrValues.count);
    
    if (_tagLastSelected > [_arrValues count])
    {
        return;
    }
    
    if (_tagLastSelected == [_arrValues count] && [_arrValues count] > 0)
    {
        _tagLastSelected = [_arrValues count] - 1;
    }
    
    
    NSArray *paths = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:_tagLastSelected inSection:0], nil];
    [self setTagLastSelected:-1];
    
    if (!self.isScrolling) {
        
        [self beginUpdates];
        [self reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
        [self endUpdates];
        
    } else {
        NSLog(@"crash occured");
        
        [self beginUpdates];
        [self reloadData];
        [self endUpdates];
        
    }
    
//    [self beginUpdates];
//    [self reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
//    [self endUpdates];
}

//Highlight a cell
- (void)highlightCellWithIndexPathRow:(NSUInteger)indexPathRow {
    
    [self setTagLastSelected:indexPathRow];

    if (!self.isScrolling) {
        
        NSArray *paths = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:_tagLastSelected inSection:0], nil];
        [self beginUpdates];
        [self reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
        [self endUpdates];

    } else {
        NSLog(@"crash occured");
        
        [self beginUpdates];
        [self reloadData];
        [self endUpdates];

    }
    
    
    SBFlatDatePicker *obj = (SBFlatDatePicker*)self.delegate;
    [obj performSelector:@selector(moveToValidDate:) withObject:self afterDelay:0];
}


@end

@interface SBFlatDatePicker ()

@property (nonatomic, strong) NSArray *arrDays;
@property (nonatomic, strong) NSArray *arrHours;
@property (nonatomic, strong) NSArray *arrMinutes;
@property (nonatomic, strong) NSArray *arrMeridians;
@property (nonatomic, strong) NSArray *arrDates;


@property (nonatomic, strong) NSArray *arrTodayHours;
@property (nonatomic, strong) NSArray *arrTodayMinutes;
@property (nonatomic, strong) NSArray *arrTodayMeridians;

@property (nonatomic, strong) SBPickerScrollView *svDays;
@property (nonatomic, strong) SBPickerScrollView *svHours;
@property (nonatomic, strong) SBPickerScrollView *svMins;
@property (nonatomic, strong) SBPickerScrollView *svMeridians;

@property (nonatomic, strong) UILabel *lblDayMonth;
@property (nonatomic, strong) UILabel *lblWeekDay;
@property (nonatomic, strong) UIButton *btPrev;
@property (nonatomic, strong) UIButton *btNext;
@property (nonatomic, strong) SBPickerButton *saveButton;
@property (nonatomic, strong) NSDateComponents *dateComps;


@end

@implementation SBFlatDatePicker


-(void)drawRect:(CGRect)rect {
    [self initialize];
    [self buildControl];
}

- (void)initialize {
    //Set the height of picker if isn't an iPhone 5 or 5s
    [self checkScreenSize];
    
    
    //Create array Meridians
    _arrMeridians = @[@"AM", @"PM"];
    
    
    _selectedDate = [NSDate date];

    NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    _dateComps = [gregorianCal components: (NSCalendarUnitHour | NSCalendarUnitMinute)
                                                  fromDate: _selectedDate];
    // Then use it
    [_dateComps minute];
    [_dateComps hour];
    
    if ([_dateComps hour] == 23 && [_dateComps minute] >=45)
    {
        _selectedDate = [_selectedDate dateByAddingTimeInterval: (60 - [_dateComps minute]) * 60];
        
        _dateComps = [gregorianCal components: (NSCalendarUnitHour | NSCalendarUnitMinute)
                                     fromDate: _selectedDate];
        // Then use it
        [_dateComps minute];
        [_dateComps hour];
    }
    
    //intialize # of days in picker. Default is 365
    [self initializeCalendarDays];
    
    //intialize # of minutes in picker. Default is 365
    [self intializeMinutes];

    
    NSLog(@"hour  %ld   min   %ld",(long)[_dateComps hour],(long)[_dateComps minute]);
    
    if ([_dateComps hour] > 12){
        
        //Create Today array Hours
        NSMutableArray *arrHours = [[NSMutableArray alloc] initWithCapacity:24];
        
        for(int i = [_dateComps hour] ; i < 24  ; i++) {
            
            if (i == [_dateComps hour])
            {
                if ([_dateComps minute] < 45)
                {
                    
                    int hour  = i % 12;
                    if(hour == 0) hour = 12;
                    [arrHours addObject:[NSString stringWithFormat:@"%@%d",(hour<10) ? @"":@"", hour]];
                }

            }
            else
            {
                int hour  = i % 12;
                if(hour == 0) hour = 12;
                [arrHours addObject:[NSString stringWithFormat:@"%@%d",(hour<10) ? @"":@"", hour]];
            }
            
        
         
        }
        
        _arrTodayHours = [NSArray arrayWithArray:arrHours];
        _arrTodayMeridians = @[@"PM"];

        
    }
    else
    {
        
        //Create Today array Hours
        NSMutableArray *arrHours = [[NSMutableArray alloc] initWithCapacity:24];
        for(int i=1; i<=12; i++) {
            
            int hour  = i % 12;
            if(hour == 0) hour = 12;
            [arrHours addObject:[NSString stringWithFormat:@"%@%d",(hour<10) ? @"":@"", hour]];
        }
        _arrTodayHours = [NSArray arrayWithArray:arrHours];
        _arrTodayMeridians = @[@"AM", @"PM"];

    }
    
    _arrTodayMinutes   = @[@"00",@"15",@"30",@"45"];
    
    
    //Create array Hours
    NSMutableArray *arrHours = [[NSMutableArray alloc] initWithCapacity:24];
    for(int i=1; i<=12; i++) {
        
        int hour  = i % 12;
        if(hour == 0) hour = 12;
        [arrHours addObject:[NSString stringWithFormat:@"%@%d",(hour<10) ? @"":@"", hour]];
    }
    _arrHours = [NSArray arrayWithArray:arrHours];
    
    //Set the acutal date
   // _selectedDate = [_selectedDate dateByAddingTimeInterval:-(3 * 86400)]; //before three days
}

-(void)intializeMinutes{
    //Create array Minutes
    __block NSMutableArray *arrMinutes = [[NSMutableArray alloc] init];
    
    //Default days is 60
    if(self.minuterange == nil){
        for(int i=0; i<60; i++) {
            [arrMinutes addObject:[NSString stringWithFormat:@"%@%d",(i<10) ? @"0":@"", i]];
        }
    } else{
        [self.minuterange enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop) {
            [arrMinutes addObject:[NSString stringWithFormat:@"%@%lu",(i<10) ? @"0":@"", (unsigned long)i]];
        }];
    }
    _arrMinutes = [NSArray arrayWithArray:arrMinutes];
}

//custom intialize based on desired forward/backward days
-(void)initializeCalendarDays{
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate* current_Date = [NSDate date];
//    current_Date = [current_Date dateByAddingTimeInterval: - (3 * 86400)]; /// need to show date picker with prev 3 days
    
    
    NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
   NSDateComponents *dateComp = [gregorianCal components: (NSCalendarUnitHour | NSCalendarUnitMinute)
                                 fromDate: current_Date];
    // Then use it
    [dateComp minute];
    [dateComp hour];
    
    if ([dateComp hour] == 23 && [dateComp minute] >=45)
    {
        current_Date = [current_Date dateByAddingTimeInterval: (60 - [dateComp minute]) * 60];
      
    }
    
    
    NSMutableArray* calendarDates = [[NSMutableArray alloc] init];
    NSMutableArray* calendarTexts = [[NSMutableArray alloc] init];
    NSDateComponents *offsetComponents = [NSDateComponents new];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    formatter.dateFormat = self.dayFormat != nil ? self.dayFormat : @"EEE MMM d";
    
    
    //Default days is 365
    if(self.dayRange == nil){
        for( int i = 0; i < 365; i++){
            //Add following year to calendar
            [offsetComponents setDay:i];
            NSDate *newDate = [gregorian dateByAddingComponents:offsetComponents toDate:current_Date options:0];
            
            NSString* dateSTring = [formatter stringFromDate:newDate];
            [calendarTexts addObject:dateSTring];
            [calendarDates addObject:newDate];
        }
        
    } else{
        [self.dayRange enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop) {
            //Add following year to calendar
            [offsetComponents setDay:i];
            NSDate *newDate = [gregorian dateByAddingComponents:offsetComponents toDate:current_Date options:0];
            
            NSString* dateSTring = [formatter stringFromDate:newDate];
            [calendarTexts addObject:dateSTring];
            [calendarDates addObject:newDate];
        }];
    }
    _arrDays = calendarTexts;
    _arrDates = calendarDates;
}


- (void)buildControl {
    //Create a view as base of the picker
  //  UIView *pickerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, PICKER_ORIGIN_Y, self.frame.size.width, PICKER_HEIGHT)];
    
    UIViewController *parentController = (UIViewController *)self.delegate;
    
    PICKER_HEIGHT = [Generals get_visible_size:parentController].height - SAVE_AREA_HEIGHT - 30;
    
//    UILabel *lbltitle = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.frame.size.width, 50.0)];
//    lbltitle.text = @"Schedule";
//    lbltitle.textColor= [UIColor whiteColor];
//    [lbltitle setFont:[UIFont fontWithName:BOLD_FONT_NAME size:24]];
//    [lbltitle setBackgroundColor:[UIColor blackColor]];
//    lbltitle.textAlignment = NSTextAlignmentCenter;

    UIView *pickerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, parentController.navigationController.navigationBar.frame.size.height, self.frame.size.width, self.frame.size.height)];
    [pickerView setBackgroundColor:[UIColor whiteColor]];

    //[UIColor colorWithRed:160/255.0f green:160/255.0f blue:160/255.0f alpha:1.0f]
    //Create bar selector
    UIView *barSel = [[UIView alloc] initWithFrame:CGRectMake(0.0, BAR_SEL_ORIGIN_Y + 10, self.frame.size.width, VALUE_HEIGHT - 20)];
    barSel.alpha = 0.9;
    [barSel setBackgroundColor:[UIColor whiteColor]];
    barSel.layer.borderColor = [UIColor blackColor].CGColor;
    barSel.layer.borderWidth = 1.0f;
    
    
    UIView *grayBg = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0, self.frame.size.width,(BAR_SEL_ORIGIN_Y + 10))];
    grayBg.alpha = 0.9;
    [grayBg setBackgroundColor:[UIColor grayColor]];
    
    
    UIView *grayBgBottom = [[UIView alloc] initWithFrame:CGRectMake(0.0, barSel.frame.origin.y +   barSel.frame.size.height, self.frame.size.width,self.frame.size.height - (barSel.frame.origin.y +   barSel.frame.size.height)  )];
    grayBgBottom.alpha = 0.9;
    [grayBgBottom setBackgroundColor:[UIColor grayColor]];


    
    //Create the first column (moments) of the picker
    _svDays = [[SBPickerScrollView alloc] initWithFrame:CGRectMake(0.0, 0, self.frame.size.width*140/320, PICKER_HEIGHT ) andValues:_arrDays withTextAlign:NSTextAlignmentRight andTextSize:18];
    _svDays.tag = 0;
    [_svDays setDelegate:self];
    [_svDays setDataSource:self];
    
    //Create the second column (hours) of the picker
    _svHours = [[SBPickerScrollView alloc] initWithFrame:CGRectMake(self.frame.size.width*140/320, 0, self.frame.size.width*60/320, PICKER_HEIGHT ) andValues:_arrTodayHours withTextAlign:NSTextAlignmentCenter  andTextSize:18];
    _svHours.tag = 1;
    [_svHours setDelegate:self];
    [_svHours setDataSource:self];
    
    //Create the third column (minutes) of the picker
    _svMins = [[SBPickerScrollView alloc] initWithFrame:CGRectMake(_svHours.frame.origin.x+self.frame.size.width*60/320, 0, self.frame.size.width*66/320, PICKER_HEIGHT ) andValues:_arrMinutes withTextAlign:NSTextAlignmentCenter andTextSize:18];
    _svMins.tag = 2;
    [_svMins setDelegate:self];
    [_svMins setDataSource:self];
    
    //Create the fourth column (meridians) of the picker
    _svMeridians = [[SBPickerScrollView alloc] initWithFrame:CGRectMake(_svMins.frame.origin.x+self.frame.size.width*60/320, 0, self.frame.size.width*66/320, PICKER_HEIGHT ) andValues:_arrTodayMeridians withTextAlign:NSTextAlignmentLeft andTextSize:18];
    _svMeridians.tag = 3;
    [_svMeridians setDelegate:self];
    [_svMeridians setDataSource:self];
    
    
    //Create separators lines
//    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width*122/320-1.0, 0.0, 1.0, PICKER_HEIGHT)];
//    [line setBackgroundColor:LINE_COLOR];
    
    UIImageView * lineImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width*140/320-1.0, 30, 1.0, PICKER_HEIGHT - 60)];
    [lineImg setImage:[UIImage imageNamed:@"datePickerSeperator"]];
    
//    UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(_svHours.frame.origin.x+self.frame.size.width*66/320-1.0, 0.0, 1.0, PICKER_HEIGHT)];
//    [line2 setBackgroundColor:LINE_COLOR];
    
    UIImageView * lineImg2 = [[UIImageView alloc] initWithFrame:CGRectMake(_svHours.frame.origin.x+self.frame.size.width*60/320-1.0, 30, 1.0, PICKER_HEIGHT - 60)];

    [lineImg2 setImage:[UIImage imageNamed:@"datePickerSeperator"]];
    
 //   UIView *line3 = [[UIView alloc] initWithFrame:CGRectMake(_svMins.frame.origin.x+self.frame.size.width*66/320-1.0, 0.0, 1.0, PICKER_HEIGHT)];
 //   [line3 setBackgroundColor:LINE_COLOR];
    
    UIImageView * lineImg3 = [[UIImageView alloc] initWithFrame:CGRectMake(_svMins.frame.origin.x+self.frame.size.width*60/320-1.0, 30, 1.0, PICKER_HEIGHT - 60)];
    [lineImg3 setImage:[UIImage imageNamed:@"datePickerSeperator"]];
    
    //Layer gradient
    CAGradientLayer *gradientLayerTop = [CAGradientLayer layer];
    gradientLayerTop.frame = CGRectMake(0.0, 0.0, pickerView.frame.size.width, PICKER_HEIGHT/3.0);
    gradientLayerTop.colors = [NSArray arrayWithObjects:(id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor, (id)self.backgroundColor.CGColor, nil];
    gradientLayerTop.startPoint = CGPointMake(0.0f, 0.7f);
    gradientLayerTop.endPoint = CGPointMake(0.0f, 0.0f);
    
    CAGradientLayer *gradientLayerBottom = [CAGradientLayer layer];
    gradientLayerBottom.frame = CGRectMake(0.0, PICKER_HEIGHT/.5, pickerView.frame.size.width, PICKER_HEIGHT/3.0);
    gradientLayerBottom.colors = gradientLayerTop.colors;
    gradientLayerBottom.startPoint = CGPointMake(0.0f, 0.3f);
    gradientLayerBottom.endPoint = CGPointMake(0.0f, 1.0f);
    
    
    //Create save area
    UIView *saveArea = [[UIView alloc] initWithFrame:CGRectMake(0.0, SAVE_AREA_ORIGIN_Y, self.frame.size.width, SAVE_AREA_HEIGHT)];
    [saveArea setBackgroundColor:[UIColor clearColor]];
    
    
    //Create save button
    _saveButton = [[SBPickerButton alloc] initWithFrame:CGRectMake(30.0, 5.0, self.frame.size.width-60.0, 45)];
    [_saveButton setTitle:@"Schedule Your Session" forState:UIControlStateNormal];
    [_saveButton addTarget:self action:@selector(saveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    
    //Add pickerView
    [self addSubview:pickerView];
    
    //Add Label
   // [self addSubview:lbltitle];
    
    
    //Add separator lines
    [pickerView addSubview:lineImg];
    [pickerView addSubview:lineImg2];
    [pickerView addSubview:lineImg3];
    
    //Add the bar selector
    [pickerView addSubview:grayBg];
    [pickerView addSubview:grayBgBottom];
    [pickerView addSubview:barSel];

    //Add scrollViews
    [pickerView addSubview:_svDays];
    [pickerView addSubview:_svHours];
    [pickerView addSubview:_svMins];
    [pickerView addSubview:_svMeridians];
    
    //Add gradients
   // [pickerView.layer addSublayer:gradientLayerTop];
   // [pickerView.layer addSublayer:gradientLayerBottom];
    
    //Add Savearea
    [self addSubview:saveArea];
    
    //Add button save
    [saveArea addSubview:_saveButton];
    
    //Set the time to now
    [self setTime:NOW];
    [self switchToDay:0];
    _svDays.tagLastSelected = 0;
    [self centerCellWithIndexPathRow:0 forScrollView:_svDays];
  
    [_btPrev setEnabled:NO];
    
    [self setUserInteractionEnabled:YES];
}



#pragma mark - Other methods

//Save button pressed
- (void)saveButtonPressed:(id)sender {
    [self setUserInteractionEnabled:YES];
    
    if (_svDays.tagLastSelected == -1 || _svHours.tagLastSelected == -1 || _svMins.tagLastSelected == -1 || _svMeridians.tagLastSelected == -1) {
        return;
    }
 
    float timeDiff = [self CheckValidDate];
    
    NSLog(@"timeDiff = %f",timeDiff);
    
    if (timeDiff >= 0) // future time
    {
        NSDate *date = [self createDateWithFormat:@"dd-MM-yyyy hh:mm a" andDateString:@"%@ %@:%@ %@"];
        
        //Send the date to the delegate
        if([_delegate respondsToSelector:@selector(flatDatePicker:saveDate:)])
            [_delegate flatDatePicker:self saveDate:date];

    }
    else if (timeDiff < 0 && timeDiff >= -60) /// with in one hour from current time
    {
        ScheduleViewController *obj = (ScheduleViewController*)self.delegate;
        
        if ([obj inServiceRange])
        {
            NSDate *date = [self createDateWithFormat:@"dd-MM-yyyy hh:mm a" andDateString:@"%@ %@:%@ %@"];

            //Send the date to the delegate
            if([_delegate respondsToSelector:@selector(flatDatePicker:saveDate:)])
                [_delegate flatDatePicker:self saveDate:date];

        }
        else
        {
            
            UIViewController *con = (UIViewController*)self.delegate;
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sorry!" message:@"You are outside of our on-demand booking area. Please schedule atleast an hour in advance so our trainer will have time to get to you!" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
//                [_svDays dehighlightLastCell];
//                [_svDays highlightCellWithIndexPathRow:3];
//                [self centerCellWithIndexPathRow:3 forScrollView:_svDays];
//
//                [self setTime:NOW];
                
                [alert dismissViewControllerAnimated:YES completion:^{
                    
                }];
            }]];
            
            // Present action sheet.
            [con presentViewController:alert animated:YES completion:nil];
            alert.view.tintColor = [UIColor blackColor];

            
        }
        
    }
    else /// past time
    {
        UIViewController *con = (UIViewController*)self.delegate;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sorry!" message:@"You are outside of our on-demand booking area. Please schedule atleast an hour in advance so our trainer will have time to get to you!" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
//            [_svDays dehighlightLastCell];
//            [_svDays highlightCellWithIndexPathRow:3];
//            [self centerCellWithIndexPathRow:3 forScrollView:_svDays];
//
//            [self setTime:NOW];
            
            [alert dismissViewControllerAnimated:YES completion:^{
                
            }];
        }]];
        
        // Present action sheet.
        [con presentViewController:alert animated:YES completion:nil];
        alert.view.tintColor = [UIColor blackColor];

    }

}

//Center the value in the bar selector
- (void)centerValueForScrollView:(SBPickerScrollView *)scrollView {
    
    //Takes the actual offset
    float offset = scrollView.contentOffset.y;
    
    //Removes the contentInset and calculates the prcise value to center the nearest cell
    offset += scrollView.contentInset.top;
    int mod = (int)offset%(int)VALUE_HEIGHT;
    float newValue = (mod >= VALUE_HEIGHT/2.0) ? offset+(VALUE_HEIGHT-mod) : offset-mod;
    
    //Calculates the indexPath of the cell and set it in the object as property
    NSInteger indexPathRow = (int)(newValue/VALUE_HEIGHT);
    
    //Center the cell
    [self centerCellWithIndexPathRow:indexPathRow forScrollView:scrollView];
}

//Center phisically the cell
- (void)centerCellWithIndexPathRow:(NSUInteger)indexPathRow forScrollView:(SBPickerScrollView *)scrollView {
    
    if(indexPathRow >= [scrollView.arrValues count]) {
        indexPathRow = [scrollView.arrValues count]-1;
    }
    
    float newOffset = indexPathRow*VALUE_HEIGHT;
    
    //Re-add the contentInset and set the new offset
    newOffset -= BAR_SEL_ORIGIN_Y;
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        if (![_svMins isScrolling] && ![_svHours isScrolling] && ![_svMeridians isScrolling]) {
            
            [_saveButton setEnabled:YES];
        }
        
        //Highlight the cell
        [scrollView highlightCellWithIndexPathRow:indexPathRow];

    }];
    
    [scrollView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexPathRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    
   // [scrollView setContentOffset:CGPointMake(0.0, newOffset) animated:YES];
    
    [CATransaction commit];
}

//Return a date from a string
- (NSDate *)createDateWithFormat:(NSString *)format andDateString:(NSString *)dateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//      NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
//      [formatter setLocale:locale];
//      NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
//      [formatter setTimeZone:gmt];
    
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];

    [formatter setDateFormat:@"EEE dd MM HH mm a"];

    formatter.dateFormat = format;
    return [formatter dateFromString:
            [NSString stringWithFormat:dateString,
             [self stringFromDate:_arrDates[_svDays.tagLastSelected] withFormat:@"dd-MM-yyyy"],
             _svHours.arrValues[_svHours.tagLastSelected],
             _svMins.arrValues[_svMins.tagLastSelected],
             _svMeridians.arrValues[_svMeridians.tagLastSelected]]];
} //edit here


//Return a string from a date
- (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString *)format {
    NSDateFormatter *formatter = [NSDateFormatter new];
//     NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
//     [formatter setLocale:locale];
////    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
////    [formatter setTimeZone:gmt];
    
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    [formatter setDateFormat:@"EEE dd MM HH mm a"];
    [formatter setDateFormat:format];
    
    return [formatter stringFromDate:date];
}


-(void)seTDay:(int)dayIndex withTime:(NSString*)selectedTime{
    
    NSLog(@"seTDay Called");

    NSLog(@"seTDay %d",dayIndex);
    
    self.selectedTime = selectedTime;
    [self setTime:selectedTime];
    [self centerCellWithIndexPathRow:dayIndex forScrollView:_svDays];
}



//Set the time automatically
- (void)setTime:(NSString *)time {
    //Get the string
    NSString *strTime;
    if([time isEqualToString:NOW])
    {
        NSTimeInterval secondsForAnHour =  74 * 60; //an hour ahead from current time
        NSDate *dateAnHoursAhead = [[NSDate date] dateByAddingTimeInterval:secondsForAnHour];
        strTime = [self stringFromDate:dateAnHoursAhead withFormat:@"hh:mm a"];
    }
    else
        strTime = (NSString *)time;
    
    //Split
    NSArray *comp = [strTime componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" :"]];
    
    //Set the tableViews
    //[_svDays dehighlightLastCell];
    [_svHours dehighlightLastCell];
    [_svMins dehighlightLastCell];
    [_svMeridians dehighlightLastCell];
    
    NSLog(@"%@",comp[2]);
    
    NSLog(@"test %@",_svMeridians.arrValues);

    
    NSString *strhour = [NSString stringWithFormat:@"%d" , ([comp[0] intValue]%12)];
    NSString *strMin = [NSString stringWithFormat:@"%d" , [comp[1] intValue] / 15];
    NSString *strMeridian = [NSString stringWithFormat:@"%@" , comp[2]];

    
    [self centerCellWithIndexPathRow:[_svHours.arrValues indexOfObject:strhour] forScrollView:_svHours];
    
    if ([comp[1] intValue] / 15 == 0)
    {
        strMin = @"00";
    }
    else if ([comp[1] intValue] / 15 == 1)
    {
        strMin = @"15";

    }
    else if ([comp[1] intValue] / 15 == 2)
    {
        strMin = @"30";

    }
    else if ([comp[1] intValue] / 15 == 3)
    {
        strMin = @"45";

    }
    
    [self centerCellWithIndexPathRow:[_svMins.arrValues indexOfObject:strMin] forScrollView:_svMins];
    [self centerCellWithIndexPathRow:[_svMeridians.arrValues indexOfObject:strMeridian] forScrollView:_svMeridians];

    

    
    
    //Center the other fields
   // [self centerCellWithIndexPathRow:([comp[0] intValue]%12)-1 forScrollView:_svHours];
//    [self centerCellWithIndexPathRow:[comp[1] intValue] / 15 forScrollView:_svMins];
//    [self centerCellWithIndexPathRow:[_arrMeridians indexOfObject:comp[2]] forScrollView:_svMeridians];
    
}

//Switch to the previous or next day
- (void)switchToDay:(NSInteger)dayOffset {
    //Calculate and save the new date
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *offsetComponents = [NSDateComponents new];
    
    //Set the offset
    [offsetComponents setDay:dayOffset];
    
    NSDate *newDate = [gregorian dateByAddingComponents:offsetComponents toDate:_selectedDate options:0];
    _selectedDate = newDate;
    
    //Show new date format
        _lblDayMonth.text = self.dayFormat != nil ? [self stringFromDate:_selectedDate withFormat:self.dayFormat] : [self stringFromDate:_selectedDate withFormat:@"dd LLLL yyyy"];
}

- (void)switchToDayPrev {
    //Check if the again previous day is a past day and in this case i disable the button
    //Calculate the new date
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *offsetComponents = [NSDateComponents new];
    
    //Set the offset
    [offsetComponents setDay:-2];
    NSDate *newDate = [gregorian dateByAddingComponents:offsetComponents toDate:_selectedDate options:0];
    
    //Get just the date and not the time
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    newDate = [dateFormatter dateFromString:[self stringFromDate:newDate withFormat:@"dd-MM-yyyy"]];
    NSDate *actDate = [dateFormatter dateFromString:[self stringFromDate:[NSDate date] withFormat:@"dd-MM-yyyy"]];
    
    //If newDate is in the past
    if([newDate compare:actDate] == NSOrderedAscending) {
        //Disable button previus day
        [_btPrev setEnabled:NO];
    }
    
    [self switchToDay:-1];
}

- (void)switchToDayNext {
    if(![_btPrev isEnabled]) [_btPrev setEnabled:YES];
    
    [self switchToDay:1];
}

//Check the screen size
- (void)checkScreenSize {
    if(IS_WIDESCREEN) {
        //1000
        PICKER_HEIGHT = (self.frame.size.height);
    } else {
        PICKER_HEIGHT = (self.frame.size.height);
    }
}

- (void)setSelectedDate:(NSDate *)date {
    _selectedDate = date;
    [self switchToDay:0];
    
    NSString *strTime = [self stringFromDate:date withFormat:@"hh:mm a"];
    [self setTime:strTime];
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//    [_svDays setUserInteractionEnabled:YES];
//    [_svDays setAlpha:0.5];
    
    if (![scrollView isDragging]) {
        NSLog(@"didEndDragging");
        [(SBPickerScrollView *)scrollView setScrolling:YES];
        [self centerValueForScrollView:(SBPickerScrollView *)scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"didEndDecelerating");
    [(SBPickerScrollView *)scrollView setScrolling:YES];
    [self centerValueForScrollView:(SBPickerScrollView *)scrollView];

}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    [_saveButton setEnabled:YES];
    
    SBPickerScrollView *sv = (SBPickerScrollView *)scrollView;
    [sv setScrolling:YES];
    [sv dehighlightLastCell];
}


-(void)reloadTime {
    
    if(_svDays.tagLastSelected == 0) {
        
        _svHours.arrValues     = [_arrTodayHours copy];
        [_svHours reloadData];
        
        if (self.selectedTime.length > 0) {
            
            [self setTime:self.selectedTime];

        } else {
            
            [self setTime:NOW];

        }
        

    }
    else
    {
        _svHours.arrValues     = [_arrHours copy];
        [_svHours reloadData];
        [self reloadMinutes];
    }
    
}

-(void)reloadMinutes {
    
    if(_svDays.tagLastSelected == 0) {
        
        int selectedHour = 0;
        
        if ([_svHours.arrValues count] > _svHours.tagLastSelected) {
            
            selectedHour = [[_svHours.arrValues objectAtIndex:_svHours.tagLastSelected] intValue];
        }
        
        
        if ((selectedHour < [self.dateComps hour] || (selectedHour == 12 &&  [self.dateComps hour] > 0) ) ) {
            
            _arrTodayMeridians = @[@"PM"];
            _svMeridians.arrValues     = [_arrTodayMeridians copy];
            
        }
        else
        {
            _arrTodayMeridians = @[@"AM",@"PM"];
            _svMeridians.arrValues     = [_arrTodayMeridians copy];
            
        }
        
        
        int  currenthour = [self.dateComps hour];
        
        NSString *selectedMeridian = @"AM";
        
        if ([_svMeridians.arrValues count] > _svMeridians.tagLastSelected) {
            
            selectedMeridian = [_svMeridians.arrValues objectAtIndex:_svMeridians.tagLastSelected];
        }
        
        if ([selectedMeridian isEqualToString:@"PM"]) {
            currenthour = [self.dateComps hour]%12;
        }
        
        if (currenthour == 0) {
            currenthour = 12;
        }
        
        if (selectedHour == currenthour)
        {
            
            if ( ([self.dateComps hour] <= 12  && [selectedMeridian isEqualToString:@"AM"]) || [self.dateComps hour] > 12)
            {
                if([self.dateComps minute] <= 15)
                {
                    _arrTodayMinutes   = @[@"15",@"30",@"45"];
                }
                else if([self.dateComps minute] <= 30)
                {
                    _arrTodayMinutes   = @[@"30",@"45"];
                }
                else if([self.dateComps minute] <= 45)
                {
                    _arrTodayMinutes   = @[@"45"];
                }
                else
                {
                    
                     if ( ([self.dateComps hour] <= 12  && [selectedMeridian isEqualToString:@"AM"]))
                     {
                         _arrTodayMinutes   = @[@"00",@"15",@"30",@"45"];
                         _arrTodayMeridians = @[@"PM"];
                         _svMeridians.arrValues     = [_arrTodayMeridians copy];
                     }
                     else
                     {
                         _arrTodayMinutes   = @[@"45"];

                     }
                    
                }
                
                _svMins.arrValues     = [_arrTodayMinutes copy];
                
            }
            else {
                
                _arrTodayMinutes   = @[@"00",@"15",@"30",@"45"];
                _svMins.arrValues     = [_arrTodayMinutes copy];
            }
           

        }
        else
        {
            _arrTodayMinutes   = @[@"00",@"15",@"30",@"45"];
            _svMins.arrValues     = [_arrTodayMinutes copy];
        }
        
        
    }
    else
    {
        _svMins.arrValues     = [_arrMinutes copy];
        
        _svMeridians.arrValues     = [_arrMeridians copy];
        
    }
    
    
    [UIView animateWithDuration:0 animations:^{
        
        [_svMins reloadData];
        
    } completion:^(BOOL finished) {
        //Do something after that...
        
        if (_svMins.tagLastSelected >= [_svMins.arrValues count])
        {
            _svMins.tagLastSelected  = [_svMins.arrValues count] - 1;
            [_svMins highlightCellWithIndexPathRow:_svMins.tagLastSelected];
        }
        
        
    }];
   
    
    
    [UIView animateWithDuration:0 animations:^{
        

        [_svMeridians reloadData];
        
    } completion:^(BOOL finished) {
        //Do something after that...
        
        if (_svMeridians.tagLastSelected >= [_svMeridians.arrValues count])
        {
            _svMeridians.tagLastSelected  = [_svMeridians.arrValues count] - 1;
            [_svMeridians highlightCellWithIndexPathRow:_svMeridians.tagLastSelected];
        }
        
    }];
    
    
    

}




-(void)moveToValidDate:(UIScrollView *)scrollView {
    
    if (scrollView == _svDays) {
        [self reloadTime];
    }
    else  if (scrollView == _svHours) {
        [self reloadMinutes];
    }
    else  if (scrollView == _svMeridians) {
        [self reloadMinutes];
    }
    
}


-(NSTimeInterval)CheckValidDate {
    
    if (_svDays.tagLastSelected != -1 && _svHours.tagLastSelected != -1 && _svMins.tagLastSelected != -1 && _svMeridians.tagLastSelected != -1) {
        
        NSDate *now = [NSDate date]; // Grab current time
        NSDate *newDate = [now dateByAddingTimeInterval:59 * 60]; // Add XXX seconds to *now
        NSTimeInterval currentInterval = [newDate timeIntervalSinceReferenceDate];
        
        NSDate *date = [self createDateWithFormat:@"dd-MM-yyyy hh:mm a" andDateString:@"%@ %@:%@ %@"];
        NSTimeInterval selectedInterval = [date timeIntervalSinceReferenceDate];
        
        long seconds = lroundf(selectedInterval - currentInterval); // Since modulo operator (%) below needs int or long
        int hours = (seconds % 86400) / 3600;
        int mins = (seconds % 3600) / 60;
        
        return (hours * 60) + mins;
    }
    
    return 0;
}

#pragma - UITableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SBPickerScrollView *sv = (SBPickerScrollView *)tableView;
    return [sv.arrValues count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = @"reusableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    SBPickerScrollView *sv = (SBPickerScrollView *)tableView;
    
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell.textLabel setFont:sv.cellFont];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    }
    
        [cell.textLabel setTextColor:(indexPath.row == sv.tagLastSelected) ? SELECTED_TEXT_COLOR : TEXT_COLOR];
        [cell.textLabel setFont:(indexPath.row == sv.tagLastSelected) ? sv.boldCellFont : sv.cellFont];
    
        [cell.textLabel setText:sv.arrValues[indexPath.row]];
    
        if (tableView == _svDays){
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
        }else {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;

        }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return VALUE_HEIGHT;
}



@end
