/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Popover view controller for choosing virtual objects to place in the AR scene.
*/

import UIKit
import ARKit
import ARObject

// MARK: - ObjectCell

class ObjectCell: UITableViewCell {
    static let reuseIdentifier = "ObjectCell"
    
    @IBOutlet weak var objectTitleLabel: UILabel!
    @IBOutlet weak var objectImageView: UIImageView!
    @IBOutlet weak var vibrancyView: UIVisualEffectView!
    
    var modelName = "" {
        didSet {
            objectTitleLabel.text = modelName.capitalized
            objectImageView.image = UIImage(named: modelName)
        }
    }
}

// MARK: - ARObjectSelectionViewControllerDelegate

/// A protocol for reporting which objects have been selected.
protocol ARObjectSelectionViewControllerDelegate: class {
    func arObjectSelectionViewController(_ selectionViewController: ARObjectSelectionViewController, updateAvailabilityFor object: ARObject) -> Bool
    func arObjectSelectionViewController(_ selectionViewController: ARObjectSelectionViewController, didSelectObject: ARObject)
    func arObjectSelectionViewController(_ selectionViewController: ARObjectSelectionViewController, didDeselectObject: ARObject)
}

/// A custom table view controller to allow users to select `ARObject`s for placement in the scene.
class ARObjectSelectionViewController: UITableViewController {
    
    /// The collection of `ARObject`s to select from.
    var arObjects = [ARObject]()
    
    /// The rows of the currently selected `ARObject`s.
    var selectedARObjectRows = IndexSet()
    
    /// The rows of the 'ARObject's that are currently allowed to be placed.
    var enabledARObjectRows = Set<Int>()
    
    weak var delegate: ARObjectSelectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .light))
    }
    
    override func viewWillLayoutSubviews() {
        preferredContentSize = CGSize(width: 250, height: tableView.contentSize.height)
    }
    
    func updateObjectAvailability() {
        var newEnabledARObjectRows = Set<Int>()
        for (row, object) in ARObjectLoader.availableObjects.enumerated() {
            // Enable row always if item is already placed, in order to allow the user to remove it.
            if selectedARObjectRows.contains(row) {
                newEnabledARObjectRows.insert(row)
            }
            else if delegate?.arObjectSelectionViewController(self, updateAvailabilityFor: object) ?? false {
                newEnabledARObjectRows.insert(row)
            }
        }
        
        // Only reload changed rows
        let changedRows = newEnabledARObjectRows.symmetricDifference(enabledARObjectRows)
        enabledARObjectRows = newEnabledARObjectRows
        let indexPaths = changedRows.map { row in IndexPath(row: row, section: 0) }

        DispatchQueue.main.async {
            self.tableView.reloadRows(at: indexPaths, with: .automatic)
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellIsEnabled = enabledARObjectRows.contains(indexPath.row)
        guard cellIsEnabled else { return }
        
        let object = arObjects[indexPath.row]
        
        // Check if the current row is already selected, then deselect it.
        if selectedARObjectRows.contains(indexPath.row) {
            delegate?.arObjectSelectionViewController(self, didDeselectObject: object)
        } else {
            delegate?.arObjectSelectionViewController(self, didSelectObject: object)
        }

        dismiss(animated: true, completion: nil)
    }
        
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arObjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ObjectCell.reuseIdentifier, for: indexPath) as? ObjectCell else {
            fatalError("Expected `\(ObjectCell.self)` type for reuseIdentifier \(ObjectCell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        
        cell.modelName = arObjects[indexPath.row].name ?? ""

        if selectedARObjectRows.contains(indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        let cellIsEnabled = enabledARObjectRows.contains(indexPath.row)
        if cellIsEnabled {
            cell.vibrancyView.alpha = 1.0
        } else {
            cell.vibrancyView.alpha = 0.1
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cellIsEnabled = enabledARObjectRows.contains(indexPath.row)
        guard cellIsEnabled else { return }

        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cellIsEnabled = enabledARObjectRows.contains(indexPath.row)
        guard cellIsEnabled else { return }

        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = .clear
    }
}
