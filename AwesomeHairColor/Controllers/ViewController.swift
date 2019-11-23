import UIKit
import Fritz

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Let's color!".uppercased()
        tableView.register(HairColorTableViewCell.self, forCellReuseIdentifier: HairColorTableViewCell.reuseId)
        tableView.tableFooterView = UIView()
        clearsSelectionOnViewWillAppear = true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? HairColorTableViewCell {
            guard let identifier = cell.reuseIdentifier else { return }
            if indexPath.row == 0 {
                var viewController = VideoHairViewController()
                self.navigationController?.pushViewController(viewController, animated: true)
            } else {
                var viewController = LiveViewController()
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
}
