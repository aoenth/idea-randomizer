//
//  ViewController.swift
//  IdeaRandomizer
//
//  Created by Kevin Peng on 2020-04-07.
//  Copyright © 2020 Monorail Apps. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
  func activate() {
    isActive = true
  }
}

class ViewController: UIViewController {
  
  private var ideas = [String]()
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
    btn.setTitle("Complete", for: .normal)
    btn.addTarget(self, action: #selector(completeRow), for: .touchUpInside)
    return btn
  }()
  
  private lazy var currentIdeaContainer: UIView = {
    let ideaView = UIView()
    ideaView.addSubview(currentIdea)
    ideaView.addSubview(completeButton)
    currentIdea.leadingAnchor.constraint(equalTo: ideaView.leadingAnchor, constant: 8).activate()
    currentIdea.trailingAnchor.constraint(equalTo: completeButton.leadingAnchor, constant: -8).activate()
    currentIdea.topAnchor.constraint(equalTo: ideaView.topAnchor, constant: 8).activate()
    currentIdea.bottomAnchor.constraint(equalTo: ideaView.bottomAnchor, constant: -8).activate()
    
    completeButton.trailingAnchor.constraint(equalTo: ideaView.trailingAnchor, constant: -8).activate()
    completeButton.topAnchor.constraint(equalTo: ideaView.topAnchor, constant: 8).activate()
    completeButton.bottomAnchor.constraint(equalTo: ideaView.bottomAnchor, constant: -8).activate()
    completeButton.widthAnchor.constraint(equalToConstant: 70).activate()
    
    return ideaView
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupTitle()
    setupBackground()
    setupLayout()
    loadData()
    createRandomizeButton()
  }
  
  func setupTitle() {
    title = "Ideas"
  }
  
  func setupBackground() {
    view.backgroundColor = .white
  }
  
  func setupLayout() {
    stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.addArrangedSubview(tableView)
    view.addSubview(stackView)
    
    let salg = view.safeAreaLayoutGuide
    stackView.topAnchor.constraint(equalTo: salg.topAnchor).isActive = true
    stackView.bottomAnchor.constraint(equalTo: salg.bottomAnchor).isActive = true
    stackView.leftAnchor.constraint(equalTo: salg.leftAnchor).isActive = true
    stackView.rightAnchor.constraint(equalTo: salg.rightAnchor).isActive = true
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
    
    self.ideas = strings
    
    tableView.reloadData()
  }
  
  func createRandomizeButton() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Choose", style: .plain, target: self, action: #selector(chooseRandomIdea))
  }
  
  func getIdeas() -> String? {
    guard let url = Bundle.main.url(forResource: "Ideas", withExtension: "csv") else {
      return nil
    }
    
    do {
      let string = try String(contentsOf: url)
      return string
    } catch {
      print("Cannot fetch ideas: \(error.localizedDescription)")
    }
    return nil
  }
  
  @objc func chooseRandomIdea() {
    var randomNumber: Int
    repeat {
      randomNumber = Int.random(in: 0 ..< ideas.count)
    } while randomNumber == previouslySelectedIdea
    
    scroll(tableView, toShowRow: randomNumber)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      self.deselectPreviouslySelectedRow(self.tableView)
      self.selectRow(self.tableView, atRow: randomNumber)
      self.showSelectedIdea(atRow: randomNumber)
    }
  }
  
  func scroll(_ tableView: UITableView, toShowRow row: Int) {
    let destinationIndexPath = IndexPath(row: row, section: 0)
    tableView.scrollToRow(at: destinationIndexPath, at: .middle, animated: true)
  }
  
  func deselectPreviouslySelectedRow(_ tableView: UITableView) {
    if let previouslySelectedIdea = previouslySelectedIdea {
      let previousIndexPath = IndexPath(row: previouslySelectedIdea, section: 0)
      if let cell = tableView.cellForRow(at: previousIndexPath) {
        cell.setSelected(false, animated: true)
      }
    }
  }
  
  func selectRow(_ tableView: UITableView, atRow row: Int) {
    let targetIndexPath = IndexPath(row: row, section: 0)
    
    if let cell = tableView.cellForRow(at: targetIndexPath) {
      cell.setSelected(true, animated: true)
    }

    previouslySelectedIdea = row
  }

  func showSelectedIdea(atRow row: Int) {
    let idea = ideas[row]
    currentIdea.text = idea
    if stackView.arrangedSubviews.count == 1 {
      stackView.insertArrangedSubview(currentIdeaContainer, at: 0)
    }
  }
  
  @objc func completeRow() {
    if let idea = currentIdea.text {
      let defaults = UserDefaults.standard
      defaults.set(true, forKey: idea)
    }
    updateCheckmark()
  }
  
  func updateCheckmark() {
    if let currentIdea = currentIdea.text {
      for (index, idea) in ideas.enumerated() {
        if idea == currentIdea {
          let indexPath = IndexPath(row: index, section: 0)
          if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
          }
        }
      }
    }
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
    cell.textLabel?.text = idea
    cell.selectionStyle = .blue
    let isCompleted = checkCompletion(idea)
    if isCompleted {
      cell.accessoryType = .checkmark
    } else {
      cell.accessoryType = .none
    }
  }
  
  private func checkCompletion(_ idea: String) -> Bool {
    let defaults = UserDefaults.standard
    return defaults.bool(forKey: idea)
  }
}


extension ViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    deselectPreviouslySelectedRow(tableView)
  }
}
