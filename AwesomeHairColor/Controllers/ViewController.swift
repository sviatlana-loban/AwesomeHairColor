import UIKit
import Fritz

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        title = "Let's color!".uppercased()
        tableView.register(HairColorTableViewCell.self, forCellReuseIdentifier: HairColorTableViewCell.reuseId)
        clearsSelectionOnViewWillAppear = true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? HairColorTableViewCell {
            guard let identifier = cell.reuseIdentifier else { return }

            var viewController = VideoHairViewController()
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
