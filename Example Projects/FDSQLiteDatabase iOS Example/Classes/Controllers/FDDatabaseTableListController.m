#import "FDDatabaseTableListController.h"
#import <FDSQLiteDatabase/FDSQLiteDatabase.h>


#pragma mark Constants

static NSString * const CellIdentifier = @"CellIdentifier";


#pragma mark - Class Extension

@interface FDDatabaseTableListController ()


@end


#pragma mark - Class Definition

@implementation FDDatabaseTableListController
{
	@private __strong FDSQLiteDatabase *_database;
	@private __strong NSArray *_tables;
	
	@private __strong UITableView *_tableView;
}


#pragma mark - Constructors

- (id)initWithDatabaseName: (NSString *)databaseName;
{
	// Abort if base initializer fails.
	if ((self = [self initWithNibName: nil 
		bundle: nil]) == nil)
	{
		return nil;
	}
	
	// Set the controller's title.
	self.title = databaseName;
	
	// Create an instance of the database.
	_database = [[FDSQLiteDatabase alloc] 
		initWithName: databaseName];
	
	// Load list of all the tables in the database.
	FDStatementResult *statementResult = [_database executeStatement: @"SELECT * FROM sqlite_master WHERE type='table' ORDER BY tbl_name ASC"];
	
	_tables = statementResult.rows;
	
	// Return initialized instance.
	return self;
}


#pragma mark - Destructor

- (void)dealloc 
{
	// nil out delegates of any instance variables.
	_tableView.delegate = nil;
	_tableView.dataSource = nil;
}


#pragma mark - Overridden Methods

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)loadView
{
	_tableView = [[UITableView alloc] 
		initWithFrame: CGRectZero 
			style: UITableViewStylePlain];
	
	_tableView.dataSource = self;
	_tableView.delegate = self;
	
	self.view = _tableView;
}

- (void)viewDidLoad
{
	// Call base implementation.
	[super viewDidLoad];
	
	// Register the table view cell class with the table view.
	[_tableView registerClass: [UITableViewCell class] 
		forCellReuseIdentifier: CellIdentifier];
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView: (UITableView *)tableView 
	numberOfRowsInSection: (NSInteger)section
{
	NSInteger numberOfRows = 0;
	
	if (tableView == _tableView)
	{
		numberOfRows = [_tables count];
	}
	
	return numberOfRows;
}

- (NSString *)tableView: (UITableView *)tableView 
	titleForHeaderInSection:(NSInteger)section
{
	NSString *title = nil;
	
	if (tableView == _tableView)
	{
		title = @"Tables";
	}
	
	return title;
}

- (UITableViewCell *)tableView: (UITableView *)tableView 
	cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
	
	if (tableView == _tableView)
	{
		cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
		
		NSDictionary *table = [_tables objectAtIndex: indexPath.row];
		
		cell.textLabel.text = [table objectForKey: @"name"];
	}
	
	return cell;
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView: (UITableView *)tableView 
	didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
	if (tableView == _tableView)
	{
	}
}


@end