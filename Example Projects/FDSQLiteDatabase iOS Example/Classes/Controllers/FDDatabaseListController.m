#import "FDDatabaseListController.h"
#import "FDDatabaseTableListController.h"


#pragma mark Constants

static NSString * const CellIdentifier = @"CellIdentifier";


#pragma mark - Class Extension

@interface FDDatabaseListController ()

- (void)_initializeDatabaseListController;


@end


#pragma mark - Class Definition

@implementation FDDatabaseListController
{
	@private __strong NSMutableArray *_databaseNames;
	
	@private __strong UITableView *_tableView;
}


#pragma mark - Constructors

- (id)initWithDefaultNibName
{
	// Abort if base initializer fails.
	if ((self = [self initWithNibName: nil 
		bundle: nil]) == nil)
	{
		return nil;
	}

	// Return initialized instance.
	return self;
}

- (id)initWithNibName: (NSString *)nibName 
    bundle: (NSBundle *)bundle
{
	// Abort if base initializer fails.
	if ((self = [super initWithNibName: nibName 
        bundle: bundle]) == nil)
	{
		return nil;
	}
	
	// Initialize view.
	[self _initializeDatabaseListController];
	
	// Return initialized instance.
	return self;
}

- (id)initWithCoder: (NSCoder *)coder
{
	// Abort if base initializer fails.
	if ((self = [super initWithCoder: coder]) == nil)
	{
		return nil;
	}
	
	// Initialize view.
	[self _initializeDatabaseListController];
	
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


#pragma mark - Private Methods

- (void)_initializeDatabaseListController
{
	// Set the title of the controller.
	self.title = @"Databases";
	
	// Construct a list of all the sqlite database files in the bundle.
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSArray *pathsForSQLiteDatabases = [mainBundle pathsForResourcesOfType: @"sqlite" 
		inDirectory: nil];
	
	_databaseNames = [NSMutableArray arrayWithCapacity: pathsForSQLiteDatabases.count];
	[pathsForSQLiteDatabases enumerateObjectsUsingBlock: ^(NSString *path, NSUInteger index, BOOL *stop)
		{
			NSString *pathComponent = [path lastPathComponent];
			
			NSString *databaseName = [pathComponent stringByDeletingPathExtension];
			
			[_databaseNames addObject: databaseName];
		}];
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView: (UITableView *)tableView 
	numberOfRowsInSection: (NSInteger)section
{
	NSInteger numberOfRows = 0;
	
	if (tableView == _tableView)
	{
		numberOfRows = [_databaseNames count];
	}
	
	return numberOfRows;
}

- (UITableViewCell *)tableView: (UITableView *)tableView 
	cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
	
	if (tableView == _tableView)
	{
		cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
		
		NSString *databaseName = [_databaseNames objectAtIndex: indexPath.row];
		
		cell.textLabel.text = databaseName;
	}
	
	return cell;
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView: (UITableView *)tableView 
	didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath: indexPath 
		animated: YES];
	
	if (tableView == _tableView)
	{
		NSString *databaseName = [_databaseNames objectAtIndex: indexPath.row];
		
		FDDatabaseTableListController *databaseTableListController = [[FDDatabaseTableListController alloc] 
			initWithDatabaseName: databaseName];
		
		[self.navigationController pushViewController: databaseTableListController 
			animated: YES];
	}
}


@end