import UIKit

class ViewController: UITableViewController {

    var searchController: IXSearchController!
    var resultController: SearchResultController!
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        
        resultController = SearchResultController()
        searchController = IXSearchController(searchResultsController: resultController)
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // you can conatraint max width of search bar
        searchController.maxSearchBarWidthWhenActive = 400
        
        // adding button to search bar is as easy as adding view to a stack view.
        searchController.leftBarItemsStack.addArrangedSubview({
            let button = UIButton(type: .system)
            button.setTitle("Filter", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.buttonFontSize)
            button.addTarget(self, action: #selector(touchUpFilterButton(_:)), for: .touchUpInside)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            return button
        }())

        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    // temporary fix for a known issue
    override func viewDidAppear(_ animated: Bool) {
        searchController.isActive = true
        searchController.isActive = false
        super.viewDidAppear(animated)
    }
    
    @objc func touchUpFilterButton(_ sender: UIButton) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier:"SearchFilterViewController")
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.sourceView = sender
        vc.popoverPresentationController?.sourceRect = sender.bounds
        vc.popoverPresentationController?.permittedArrowDirections = [.up]
        searchController.present(vc, animated: true, completion: nil)
    }
    
}

extension ViewController: UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let resultController = searchController.searchResultsController as? UITableViewController else { return }
        resultController.tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(#function, resultController.view.safeAreaInsets)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print(#function)
    }

}

extension ViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Testing"
        return cell
    }
    
}
