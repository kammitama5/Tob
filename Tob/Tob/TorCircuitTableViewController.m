//
//  TorCircuitTableViewController.m
//  Tob
//
//  Created by Jean-Romain on 20/01/2018.
//  Copyright © 2018 JustKodding. All rights reserved.
//

#import "TorCircuitTableViewController.h"
#import "AppDelegate.h"

@interface TorCircuitTableViewController ()

@end

@implementation TorCircuitTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(goBack)];
    self.navigationItem.rightBarButtonItem = backButton;

    self.navigationItem.title = NSLocalizedString(@"Tor circuits", nil);
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    return [[[appDelegate tor] currentCircuits] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    TorCircuit *circuit = [[[appDelegate tor] currentCircuits] objectAtIndex:section];
    return [[circuit nodes] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    TorCircuit *circuit = [[[appDelegate tor] currentCircuits] objectAtIndex:section];
    
    NSString *title;
    if ([circuit isCurrentCircuit]) {
        title = [NSString stringWithFormat:NSLocalizedString(@"Circuit %@ (current)", nil), circuit.ID];
    } else {
        title = [NSString stringWithFormat:NSLocalizedString(@"Circuit %@", nil), circuit.ID];
    }
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle]; // MM/dd/yyyy
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle]; // hh:mm
    NSString *dateString = [dateFormatter stringFromDate:circuit.timeCreated];

    title = [title stringByAppendingString:[NSString stringWithFormat:@"\n%@", dateString]];
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NodeInfo"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"NodeInfo"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    TorCircuit *circuit = [[[appDelegate tor] currentCircuits] objectAtIndex:indexPath.section];
    TorNode *node = [[circuit nodes] objectAtIndex:indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@ (%@)", node.name, node.IP, node.country];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@ KB/s", node.version, node.bandwidth];

    return cell;
}

@end
