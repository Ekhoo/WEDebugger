//
//  WEDebuggerViewController.m
//  WEDebugger
//
//  Created by Lucas Ortis on 17/03/2016.
//  Copyright © 2016 Lucas Ortis. All rights reserved.
//

#import "WEDebuggerViewController.h"
#import "Masonry.h"
#import "WEDebugger.h"
#import "WELogCell.h"

static CGFloat kCompactedCellHeight = 100.0f;

@interface WEDebuggerViewController ()

@property(nonatomic, strong, readonly) UITableView *terminal;
@property(nonatomic, strong, readonly) UITextField *search;
@property(nonatomic, strong, readwrite) NSMutableArray *data;
@property(nonatomic, strong, readwrite) NSMutableDictionary *expandedCells;
@property(nonatomic, assign, readwrite) BOOL didSetupConstraints;

@end

@implementation WEDebuggerViewController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _didSetupConstraints = NO;
        _data = [NSMutableArray array];
        _expandedCells = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    _search = [UITextField new];
    _search.layer.borderColor = [UIColor whiteColor].CGColor;
    _search.layer.borderWidth = 1.0f;
    _search.placeholder = @"Rechercher";
    _search.textAlignment = NSTextAlignmentCenter;
    _search.textColor = [UIColor whiteColor];
    _search.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Rechercher" attributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    _search.autocorrectionType = UITextAutocorrectionTypeNo;
    _search.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _search.returnKeyType = UIReturnKeyDone;
    _search.delegate = self;
    _search.tintColor = [UIColor whiteColor];
    [_search addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    _terminal = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _terminal.backgroundColor = [UIColor blackColor];
    _terminal.delegate = self;
    _terminal.dataSource = self;
    
    [_terminal registerClass:[WELogCell class] forCellReuseIdentifier:@"WE_LOG_CELL"];
    
    [self.view addSubview:_search];
    [self.view addSubview:_terminal];
    
    [self fillTerminal];
    
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeDebugger)];
    gesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:gesture];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapView)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:singleTap];
    
    [self.view setNeedsUpdateConstraints];
}

- (void)updateViewConstraints {
    if (!_didSetupConstraints) {
        _didSetupConstraints = YES;
        
        [_search mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.view).with.offset(24.0f);
            make.left.mas_equalTo(self.view).with.offset(16.0f);
            make.right.mas_equalTo(self.view).with.offset(-16.0f);
            make.height.mas_equalTo(40.0f);
            
            _search.layer.cornerRadius = 20.0f;
        }];
        
        [_terminal mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(_search.mas_bottom).with.offset(16.0f);
            make.left.mas_equalTo(self.view).with.offset(16.0f);
            make.right.mas_equalTo(self.view).with.offset(-16.0f);
            make.bottom.mas_equalTo(self.view).with.offset(-16.0f);
        }];
    }
    
    [super updateViewConstraints];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)fillTerminal {
    [_data removeAllObjects];
    
    [_data addObjectsFromArray:[WEDebugger sharedInstance].logs];
    
    [_terminal reloadData];
}

- (void)closeDebugger {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleTapView {
    [_search resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WELogCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WE_LOG_CELL"];
    WELog *log = _data[indexPath.row];
    CGFloat cellHeight = [self computeCellHeightFromIndexPath:indexPath];
    
    if (cellHeight > kCompactedCellHeight) {
        cell.canExpand = YES;
        cell.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
    } else {
        cell.canExpand = NO;
        cell.backgroundColor = [UIColor blackColor];
    }
    
    [cell setLog:log];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)computeCellHeightFromIndexPath:(NSIndexPath *)indexPath {
    WELog *log = _data[indexPath.row];
    CGSize maxSize = CGSizeMake([UIScreen mainScreen].bounds.size.width - 32.0f, CGFLOAT_MAX);
    UIFont *font = [UIFont systemFontOfSize:14.0f];
    CGRect frameCell = [log.log boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font} context:nil];
    
    return frameCell.size.height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellHeight = [self computeCellHeightFromIndexPath:indexPath];
    
    if (cellHeight > kCompactedCellHeight && !_expandedCells[@(indexPath.row)]) {
        return kCompactedCellHeight;
    }
    
    return cellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WELogCell *cell = (WELogCell *)[self tableView:_terminal cellForRowAtIndexPath:indexPath];
    
    if (cell.canExpand) {
        if ([_expandedCells objectForKey:@(indexPath.row)]) {
            [_expandedCells removeObjectForKey:@(indexPath.row)];
        } else {
            _expandedCells[@(indexPath.row)] = @(YES);
        }
        
        [_terminal beginUpdates];
        [_terminal endUpdates];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField {
    [_data removeAllObjects];
    
    
    if (textField.text && textField.text.length > 0) {
        for (WELog *log in [WEDebugger sharedInstance].logs) {
            if ([log.log rangeOfString:textField.text options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [_data addObject:log];
            }
        }
        
        [_terminal reloadData];
    } else {
        [self fillTerminal];
    }
}

@end
