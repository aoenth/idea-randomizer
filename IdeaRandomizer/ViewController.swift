//
//  ViewController.swift
//  IdeaRandomizer
//
//  Created by Kevin Peng on 2020-04-07.
//  Copyright © 2020 Monorail Apps. All rights reserved.
//

import UIKit

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
    return tv
  }()
  
  private lazy var currentIdea: UILabel = {
    let lbl = UILabel()
    lbl.translatesAutoresizingMaskIntoConstraints = false
    lbl.textAlignment = .center
    return lbl
  }()
  
  private lazy var currentIdeaContainer: UIView = {
    let ideaView = UIView()
    ideaView.translatesAutoresizingMaskIntoConstraints = false
    ideaView.addSubview(currentIdea)
    
    currentIdea.topAnchor.constraint(equalTo: ideaView.topAnchor, constant: 8).isActive = true
    currentIdea.bottomAnchor.constraint(equalTo: ideaView.bottomAnchor, constant: 8).isActive = true
    currentIdea.leftAnchor.constraint(equalTo: ideaView.leftAnchor, constant: 8).isActive = true
    currentIdea.rightAnchor.constraint(equalTo: ideaView.rightAnchor, constant: 8).isActive = true
    currentIdea.heightAnchor.constraint(equalToConstant: 44).isActive = true
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

}

extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath)
    cell.textLabel?.text = ideas[indexPath.row]
    cell.selectionStyle = .blue
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    ideas.count
  }
}

