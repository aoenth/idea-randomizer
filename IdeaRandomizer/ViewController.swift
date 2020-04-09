//
//  ViewController.swift
//  IdeaRandomizer
//
//  Created by Kevin Peng on 2020-04-07.
//  Copyright © 2020 Monorail Apps. All rights reserved.
//

import UIKit
import NotificationCenter

extension NSLayoutConstraint {
  func activate() {
    isActive = true
  }
}

class ViewController: UIViewController {
  
  private var ideas = [Idea]()
  private let CELL_ID = "CELL_ID"
  private var previouslySelectedIdea: Int?
  private var stackView: UIStackView!
  
  private lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.register(UITableViewCell.self, forCellReuseIdentifier: CELL_ID)
    tv.dataSource = self
    tv.delegate = self
    return tv
  }()
  
  private lazy var currentIdeaIndicator: UILabel = {
    let lbl = UILabel()
    lbl.text = "Idea Currently Working On:"
    lbl.font = .preferredFont(forTextStyle: .subheadline)
    lbl.translatesAutoresizingMaskIntoConstraints = false
    lbl.textAlignment = .center
    return lbl
  }()
  
  private lazy var currentIdea: UILabel = {
    let lbl = UILabel()
    lbl.translatesAutoresizingMaskIntoConstraints = false
    lbl.textAlignment = .center
    lbl.numberOfLines = 0
    return lbl
  }()
  
  private lazy var completeButton: UIButton = {
    let btn = UIButton(type: .system)
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setTitle("Mark as Complete", for: .normal)
    btn.titleLabel?.numberOfLines = 2
    btn.addTarget(self, action: #selector(completeRow), for: .touchUpInside)
    return btn
  }()
  
  private lazy var currentIdeaContainer: UIView = {
    let ideaView = UIView()
    ideaView.addSubview(currentIdea)
    ideaView.addSubview(completeButton)
    ideaView.addSubview(currentIdeaIndicator)
    ideaView.layer.borderWidth = 0.5
    ideaView.layer.borderColor = UIColor.systemGray.cgColor
    
    currentIdeaIndicator.topAnchor.constraint(equalTo: ideaView.topAnchor, constant: 8).activate()
    currentIdeaIndicator.leadingAnchor.constraint(equalTo: ideaView.leadingAnchor,constant: 8).activate()
    currentIdeaIndicator.trailingAnchor.constraint(equalTo: completeButton.leadingAnchor, constant: -8).activate()
    
    currentIdea.leadingAnchor.constraint(equalTo: ideaView.leadingAnchor, constant: 8).activate()
    currentIdea.trailingAnchor.constraint(equalTo: completeButton.leadingAnchor, constant: -8).activate()
    currentIdea.topAnchor.constraint(equalTo: currentIdeaIndicator.bottomAnchor, constant: 4).activate()
    currentIdea.bottomAnchor.constraint(equalTo: ideaView.bottomAnchor, constant: -8).activate()
    
    completeButton.trailingAnchor.constraint(equalTo: ideaView.trailingAnchor, constant: -8).activate()
    completeButton.topAnchor.constraint(equalTo: ideaView.topAnchor, constant: 8).activate()
    completeButton.bottomAnchor.constraint(equalTo: ideaView.bottomAnchor, constant: -8).activate()
    completeButton.widthAnchor.constraint(equalToConstant: 70).activate()
    return ideaView
  }()
  
  //MARK: completeButton Methods
  @objc func completeRow() {
    markRowAsComplete()
  }
  
  func markRowAsComplete() {
    if let currentIdea = currentIdea.text {
      for (index, idea) in ideas.enumerated() {
        if idea.shortDescription == currentIdea {
          markRowWithCheckmark(index)
          ideas[index].isInProgress = false
          ideas[index].isComplete = true
          
          hideCurrentIdeaContainer()
        }
      }
    }
  }
  
  func markRowWithCheckmark(_ row: Int) {
    let indexPath = IndexPath(row: row, section: 0)
    if let cell = tableView.cellForRow(at: indexPath) {
      cell.accessoryType = .checkmark
    }
  }
  
  //MARK: - Life cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupTitle()
    setupBackground()
    setupLayout()
    loadData()
    createRandomizeButton()
    addResignActiveObserver()
    #if DEBUG
    createSaveButton()
    addDebugButton()
    #endif
  }
  
  //MARK: - viewDidLoad Methods
  
  func setupTitle() {
    navigationItem.largeTitleDisplayMode = .always
    title = "Ideas"
  }
  
  func setupBackground() {
    if #available(iOS 13, *) {
      view.backgroundColor = .systemBackground
    } else {
      view.backgroundColor = .white
    }
  }
  
  func setupLayout() {
    stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.addArrangedSubview(tableView)
    view.addSubview(stackView)
    
    let salg = view.safeAreaLayoutGuide
    stackView.topAnchor.constraint(equalTo: salg.topAnchor).activate()
    stackView.bottomAnchor.constraint(equalTo: salg.bottomAnchor).activate()
    stackView.leftAnchor.constraint(equalTo: salg.leftAnchor).activate()
    stackView.rightAnchor.constraint(equalTo: salg.rightAnchor).activate()
  }
  
  func loadData() {
    guard let ideas = getIdeas() else {
      return
    }
    
    var strings = ideas.components(separatedBy: "\n")
    if let last = strings.last {
      if last == "" {
        _ = strings.removeLast()
      }
    }
    
    let ideaStructs: [Idea] = strings.map { (line) in
      let separated = line.components(separatedBy: ":::")
      let ideaDescription = separated.first!
      let isCompleted: Bool
      let isInProgress: Bool
      
      if separated.count > 2 {
        isInProgress = separated[1] == "1"
        isCompleted = separated[2] == "1"
      } else {
        isInProgress = false
        isCompleted = false
      }
      
      return Idea(shortDescription: ideaDescription,
                  isInProgress: isInProgress,
                  isComplete: isCompleted)
    }
    
    self.ideas = ideaStructs
    
    tableView.reloadData()
    findInProgress()
  }
  
  func createRandomizeButton() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Choose", style: .plain, target: self, action: #selector(chooseRandomIdea))
  }
  
  #if DEBUG
  func createSaveButton() {
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveToDisk))
  }
  #endif
  
  func addResignActiveObserver() {
    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(self, selector: #selector(saveToDisk), name: UIApplication.willResignActiveNotification, object: nil)
  }
  
  #if DEBUG
  func addDebugButton() {
    let debugButton = UIBarButtonItem(title: "Debug", style: .plain, target: self, action: #selector(showDebugOptions))
    navigationItem.leftBarButtonItems?.append(debugButton)
  }
  #endif
  
  //MARK: loadData Methods
  
  func getIdeas() -> String? {
    let url = getDocumentsDirectory().appendingPathComponent("Ideas.csv")
    
    do {
      let string = try String(contentsOf: url)
      return string
    } catch {
      handleFileDoesNotExist()
      print("Cannot fetch ideas: \(error.localizedDescription)")
    }
    return nil
  }
  
  private func findInProgress() {
    let inProgress = ideas.filter { $0.isInProgress }
    if let inProgressIdea = inProgress.first {
      showInProgress(forIdea: inProgressIdea)
    }
  }
  
  //MARK: createRandomizeButton Methods
  
  @objc func chooseRandomIdea() {
    var randomNumber: Int
    repeat {
      randomNumber = Int.random(in: 0 ..< ideas.count)
    } while randomNumber == previouslySelectedIdea && ideas.count > 1
    
    deselectPreviouslySelectedRow(tableView)
    markRowAsInProgress(randomNumber)
    showSelectedIdea(atRow: randomNumber)
    scroll(tableView, toShowRow: randomNumber)
    previouslySelectedIdea = randomNumber
  }
  
  //MARK: addResignActiveObserver Methods
  @objc func saveToDisk() {
    writeToFile()
  }
  
  //MARK: addDebugButton Methods
  #if DEBUG
  @objc func showDebugOptions() {
    let alertController = UIAlertController(title: "Options", message: nil, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Mark All As \"In Progress\"", style: .default, handler: markAllAsInProgress))
    alertController.addAction(UIAlertAction(title: "Mark All As \"Complete\"", style: .default, handler: markAllAsComplete))
    alertController.addAction(UIAlertAction(title: "Mark All As \"Incomplete\"", style: .default, handler: markAllAsIncomplete))
    alertController.addAction(UIAlertAction(title: "Mark All As \"Not In Progress\"", style: .default, handler: markAllAsNotInProgress))
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    present(alertController, animated: true)
  }
  #endif
  
  //MARK: - Level 2
  
  //MARK: getIdeas Methods
  func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
  }
  
  func handleFileDoesNotExist() {
    let alertController = UIAlertController(title: "New Idea", message: "Seems like you don't have any ideas yet, would you like to create one?", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: createNewIdea))
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    present(alertController, animated: true, completion: nil)
  }
  
  //MARK: findInProgress Methods
  private func showInProgress(forIdea idea: Idea) {
    currentIdea.text = idea.shortDescription
    showCurrentIdeaContainer()
  }
  
  //MARK: chooseRandomIdea Methods
  func deselectPreviouslySelectedRow(_ tableView: UITableView) {
    if let previouslySelectedIdea = previouslySelectedIdea {
      let previousIndexPath = IndexPath(row: previouslySelectedIdea, section: 0)
      if let cell = tableView.cellForRow(at: previousIndexPath) {
        cell.setSelected(false, animated: true)
      }
    }
  }
  
  func markRowAsInProgress(_ row: Int) {
    ideas[row].isInProgress = true
    markRowWithDetailButton(row)
  }
  
  func scroll(_ tableView: UITableView, toShowRow row: Int) {
    let destinationIndexPath = IndexPath(row: row, section: 0)
    tableView.scrollToRow(at: destinationIndexPath, at: .middle, animated: true)
  }
  
  //MARK: saveToDisk Methods
  func writeToFile() {
    let stringToWrite = createCSV()
    let directory = getDocumentsDirectory().appendingPathComponent("Ideas.csv")
    print(directory.absoluteString)
    print(stringToWrite)
    do {
      try stringToWrite.write(to: directory, atomically: true, encoding: String.Encoding.utf8)
    } catch {
      fatalError("Cannot be saved to CSV: \(error.localizedDescription)")
    }
    
  }
  
  //MARK: writeToFile Methods
  func createCSV() -> String {
    var finalString = ""
    for idea in self.ideas {
      let inProgress = idea.isInProgress ? 1 : 0
      let isComplete = idea.isComplete ? 1 : 0
      finalString += idea.shortDescription + ":::\(inProgress):::\(isComplete)\n"
    }
    return finalString
  }
  
  //MARK: showDebugOptions Methods
  #if DEBUG
  func markAllAsInProgress(_ alert: UIAlertAction) {
    let keyPath = \Idea.isInProgress
    markAs(keyPath: keyPath, bool: true)
  }
  
  func markAllAsComplete(_ alert: UIAlertAction) {
    let keyPath = \Idea.isComplete
    markAs(keyPath: keyPath, bool: true)
  }
  
  func markAllAsIncomplete(_ alert: UIAlertAction) {
    let keyPath = \Idea.isComplete
    markAs(keyPath: keyPath, bool: false)
  }
  
  func markAllAsNotInProgress(_ alert: UIAlertAction) {
    let keyPath = \Idea.isInProgress
    markAs(keyPath: keyPath, bool: false)
  }
  
  func markAs(keyPath: WritableKeyPath<Idea, Bool>, bool: Bool) {
    for i in 0 ..< ideas.count {
      ideas[i][keyPath: keyPath] = bool
    }
    tableView.reloadData()
  }
  #endif
  
  //MARK: handleFileDoesNotExist Methods
  func createNewIdea(_ alert: UIAlertAction) {
    let alertController = UIAlertController(title: "New Idea", message: nil, preferredStyle: .alert)
    alertController.addTextField(configurationHandler: configureTextField)
    alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
      if let ideaText = alertController.textFields?.first?.text {
        self.createNewIdea(ideaText)
        self.tableView.reloadData()
      }
    })
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    present(alertController, animated: true, completion: nil)
  }
  
  //MARK: createNewIdea Methods
  func configureTextField(_ textField: UITextField) {
    textField.placeholder = "Turn photo into black and white app"
  }
  
  func createNewIdea(_ ideaDescription: String) {
    ideas.append(Idea(shortDescription: ideaDescription))
  }
  
  //MARK: markRowAsInProgress Methods
  func markRowWithDetailButton(_ row: Int) {
    let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0))
    cell?.accessoryType = .detailButton
  }
}

extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath)

    configureCell(cell, indexPath: indexPath)
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    ideas.count
  }
  
  private func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
    let idea = ideas[indexPath.row]
    cell.textLabel?.text = idea.shortDescription
    
    if idea.isComplete {
      cell.accessoryType = .checkmark
    } else if idea.isInProgress {
      cell.accessoryType = .detailButton
    } else {
      cell.accessoryType = .none
    }
  }
  
}

extension ViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    deselectPreviouslySelectedRow(tableView)
    previouslySelectedIdea = indexPath.row
  }
  
  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    if let ideaIndex = previouslySelectedIdea {
      self.selectRow(scrollView as! UITableView, atRow: ideaIndex)
    }
  }
  
  //MARK: scrollViewDidEndScrollingAnimation Methods
  func selectRow(_ tableView: UITableView, atRow row: Int) {
    let targetIndexPath = IndexPath(row: row, section: 0)
    
    if let cell = tableView.cellForRow(at: targetIndexPath) {
      cell.setSelected(true, animated: true)
      setInProgress(row)
    }
    
    previouslySelectedIdea = row
  }
  
  func showSelectedIdea(atRow row: Int) {
    let idea = ideas[row]
    currentIdea.text = idea.shortDescription
    if stackView.arrangedSubviews.count == 1 {
      showCurrentIdeaContainer()
    }
  }
  
  //MARK: selectRow Methods
  func setInProgress(_ row: Int) {
    ideas[row].isInProgress = true
  }
  
  //MARK: showSelectedIdea Methods
  func showCurrentIdeaContainer() {
    stackView.addArrangedSubview(currentIdeaContainer)
  }
  
  //MARK: markRowAsComplete Methods
  func hideCurrentIdeaContainer() {
    stackView.removeArrangedSubview(currentIdeaContainer)
  }
}
