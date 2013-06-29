#pragma mark Class Interface

@interface FDDatabaseTableListController : UIViewController<
	UITableViewDataSource, 
	UITableViewDelegate>


#pragma mark - Constructors

- (id)initWithDatabaseName: (NSString *)databaseName;


@end