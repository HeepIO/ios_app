//
//  DeviceSummaryViewController.swift
//  mobile_ios
//
//  Created by Jacob Keith on 5/10/17.
//  Copyright © 2017 Heep. All rights reserved.
//

import UIKit

class DeviceSummaryViewController: UITableViewController {
    
    var referenceList = [String?]()
    
    var sections: [String]!
    var cells: [[String]]!
    
    var thisDevice = Device()
    var controls = [DeviceControl]()
    var vertices = [Vertex]()
    
    var userIds: [Int] = []
    var userRealmKeys: [String] = []
    var adminUser: User? = nil
    var authorizedUsers = [Int : User]()
    var deviceID: Int = 0
    
    
    func resetEverything() {
        sections = []
        cells = []
        controls = []
        userIds = []
        userRealmKeys = []
        
    }
    
    init(deviceID: Int) {
        
        super.init(style: UITableViewStyle.plain)
        self.deviceID = deviceID
        self.resetEverything()
        self.initNotifications()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = thisDevice.name
        self.tableView.separatorStyle = .none
        
        //database().updateDeviceUserList(deviceID: thisDevice.deviceID)
        
        self.prepareEverything()
    }

    
    deinit{
        for reference in referenceList {
            if let refPath = reference {
                database().detachObserver(referencePath: refPath)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        for reference in referenceList {
            if let refPath = reference {
                database().detachObserver(referencePath: refPath)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.initNotifications()
    }
    
    
    func initNotifications() {
        
        self.referenceList.append(database().watchDevice(deviceID: deviceID, reset: {
            self.resetEverything()
            
        }, identity: { device in
            
            print(device)
            self.thisDevice = device
            self.updateView()
            
        }, controls: { control in
            
            self.controls.append(control)
            self.updateView()
            
        }, vertices: { vertex in
            
            print(vertex)
            self.vertices.append(vertex)
            self.updateView()
            
        }))
    }
    
    func updateView() {
        self.prepareEverything()
        self.tableView.reloadData()
        self.viewDidLoad()
    }
    
    func prepareEverything() {
        
        self.prepareUserData()
        self.prepareDeviceData()
        self.prepareControls()
        self.prepareVertices()
    }
    
    func prepareControls() {
        
        for control in controls {
            prepareControlData(control: control)
            
        }
    }
    
    func prepareVertices() {
        for vertex in vertices {
            prepareVertex(vertex: vertex)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupNavToolbar() {
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let claim = UIBarButtonItem(title: "Claim Device",
                                    style: .plain,
                                    target: self,
                                    action: #selector(claimDevice))
        
        let grant = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addUserToThisDevice))
        
        self.toolbarItems = [spacer,  claim, spacer, grant]
    }
    
    func prepareUserData() {
        self.sections = ["Users with Access"]
        var humanData = [String]()
        
        if thisDevice.humanAdmin != 0 {
            userIds.append(thisDevice.humanAdmin)
            
            if self.adminUser == nil {
                database().getAuthorizedUsers(deviceID: thisDevice.deviceID){ profile in
                    print(profile)
                    self.authorizedUsers[profile.heepID] = profile
                    self.updateView()
                }
            }
            
            if self.adminUser == nil {
                database().getUserProfile(heepID: thisDevice.humanAdmin) { profile in
                    
                    self.adminUser = profile
                    self.updateView()
                }
            }
            
            humanData.append("admin")
            
            if self.adminUser == nil {
                database().getAuthorizedUsers(deviceID: thisDevice.deviceID){ profile in
                    self.authorizedUsers[profile.heepID] = profile
                    self.updateView()
                }
            }
            
            humanData.append("addNewUser")
            
        } else {
            print("This Device's owner is not registered in the Heep User Directory")
            humanData.append("claimDevice")
        }
        
        self.cells = [humanData]
    }
    
    func prepareDeviceData() {
        
        self.sections.append("Device: " + thisDevice.name)
        
        var deviceData = [String]()
        let deviceProps = thisDevice.propertyNames()
        var nextValue = ""
        
        for property in deviceProps {
            if property == "controlList" {
                continue
            }
            
            if let value = thisDevice.value(forKey: property) {
                nextValue = "\(property): \(String.init(describing: value))"
            } else {
                nextValue = "\(property): nil"
            }
            
            deviceData.append(nextValue)
        }
        
        self.cells.append(deviceData)
        
    }
    
    
    func prepareControlData(control: DeviceControl) {
        
        self.sections.append("Control: " + control.controlName)
        
        var controlData = [String]()
        let controlProps = control.propertyNames()
        var nextValue = ""
        
        for property in controlProps {
            if property == "vertexList" {
                continue
            }
            
            if let value = control.value(forKey: property) {
                nextValue = "\(property): \(String.init(describing: value))"
            } else {
                nextValue = "\(property): nil"
            }
            
            controlData.append(nextValue)
        }
        
        self.cells.append(controlData)
    }
    
    func prepareVertex(vertex: Vertex) {
        self.sections.append("Vertex: " + vertex.vertexID)
        
        let txName = "tx Name: " + (vertex.tx?.controlName)!
        let txID = "tx ID: " + String(describing: (vertex.tx?.uniqueID)!)
        let rxName = "rx Name: " + (vertex.rx?.controlName)!
        let rxID = "rx ID: " + String(describing: (vertex.rx?.uniqueID)!)
        
        let thisVertex = [txName, txID, rxName, rxID]
        self.cells.append(thisVertex)
    }
    
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {

        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 45
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        let label = UILabel()
        label.frame = CGRect(x: 5, y: 5, width: tableView.frame.size.width, height: 35)
        label.text = self.sections[section]
        view.addSubview(label)
        
        return view
        
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.cells[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell()
        
        if indexPath.section == 0 {
            switch self.cells[indexPath.section][indexPath.row] {
            case "admin" :
                if let adminProfile = self.adminUser {
                    cell.addSubview(self.addUserCell(profile: adminProfile, initialOffset: 15))
                }
                
            case "claimDevice" :
                cell.addSubview(addClaimDeviceCell())
                
            case "addNewUser" :
                cell.addSubview(addNewUserCell())
                
            default:
                let authUserKeys = [Int](self.authorizedUsers.keys)
                let thisKey = authUserKeys[indexPath.row]
                print("KEY: \(thisKey)")
                if let thisUser = self.authorizedUsers[thisKey] {
                    print("NEXT USER: \(thisUser)")
                    cell.addSubview(self.addUserCell(profile: thisUser, initialOffset: 60))
                }
                
            }
            
        } else {
            
            let label = UILabel()
            label.text = self.cells[indexPath.section][indexPath.row]
            label.frame = CGRect(x: 60, y: 5, width: tableView.frame.size.width, height: 35)
            cell.addSubview(label)
            cell.selectionStyle = .none
        }
        
        
        return cell
    }
    
    func addUserCell(profile: User, initialOffset: CGFloat = 60) -> UIView {
        print(profile)
        
        let userView = UIView(frame: CGRect(x: 0 + initialOffset,
                                            y: 0,
                                            width: tableView.frame.size.width,
                                            height: 45))
        
        let userIcon = userIconView(startingframe: CGRect(x: 60,
                                                          y: 0,
                                                          width: 45,
                                                          height: 45),
                                    userID: profile.heepID)
        
        userView.addSubview(userIcon.view)
        
        let userName = userNameView(frame: CGRect(x: userIcon.frame.maxX + 10,
                                                   y: 0,
                                                   width: (tableView.frame.size.width - userIcon.frame.maxX) / 5,
                                                   height: 45),
                                    name: profile.name,
                                    textAlignment: .left,
                                    calculateFrame: false)
        
        
        userView.addSubview(userName.view)
        
        let userEmail = userEmailView(frame: CGRect(x: userName.frame.maxX + 10,
                                                   y: 0,
                                                   width: tableView.frame.size.width - userIcon.frame.maxX,
                                                   height: 45),
                                      email: profile.email,
                                      textAlignment: .left,
                                      calculateFrame: false)
        
        userView.addSubview(userEmail.view)
        
        return userView
    }
    
    func addClaimDeviceCell() -> UIView {
        
        let button = UIButton(frame: CGRect(x: 0,
                                            y: 5,
                                            width: tableView.frame.size.width,
                                            height: 35))
        
        button.setTitle("Claim this Device?", for: .normal)
        button.setTitleColor(self.view.tintColor, for: .normal)
        button.addTarget(self, action: #selector(claimDevice), for: .primaryActionTriggered)
        
        return button
    }
    
    func addNewUserCell() -> UIView {
        let button = UIButton(frame: CGRect(x: 0,
                                            y: 5,
                                            width: tableView.frame.size.width,
                                            height: 35))
        
        button.setTitle("Grant access to a new User", for: .normal)
        button.setTitleColor(self.view.tintColor, for: .normal)
        button.addTarget(self, action: #selector(addUserToThisDevice), for: .primaryActionTriggered)
        
        return button
    }
    
    func claimDevice() {
        //HeepConnections().sendAssignAdminToHeepDevice(deviceID: thisDevice.deviceID)
        
        database().getMyHeepID() { heepID in
            
            let updateDevice = Device(value: self.thisDevice)
            updateDevice.humanAdmin = heepID!
            
            database().updateDevice(device: updateDevice)
            
        }
        
    }
    
    func addUserToThisDevice() {
        let modalViewController = UserSearch(device: thisDevice)
        modalViewController.modalPresentationStyle = .overCurrentContext
        present(modalViewController, animated: false) {}
    }
    
    
    func reloadView() {
        
        self.loadView()
        self.viewDidLoad()
    }
    
}
