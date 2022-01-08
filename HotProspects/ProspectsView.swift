//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Heath Fashina on 2022-01-03.
//

import CodeScanner
import SwiftUI
import UserNotifications

struct ProspectsView: View {
    enum FilterType {
        case none, contacted, uncontacted
    }
    
    enum SortType {
        case name, creationDate
    }
    
    @EnvironmentObject var prospects: Prospects
    @State private var isShowingScanner = false
    
    @State private var showSortDialog = false
    @State private var sortBy: SortType = .name
    
    let filter: FilterType
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedProspects) { prospect in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer ()
                        
                        if prospect.isContacted && filter == .none {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, .gray)
                        }
                    }
                    .swipeActions {
                        if prospect.isContacted {
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Uncontacted", systemImage: "person.crop.circle.badge.xmark")
                            }
                            .tint(.blue)
                        } else {
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark")
                            }
                            .tint(.green)
                            
                            Button {
                                addNotification(for: prospect)
                            } label: {
                                Label("Remind Me", systemImage: "bell")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSortDialog = true
                    } label: {
                        Text("Sort")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingScanner = true
                    } label: {
                        Label("Scan", systemImage: "qrcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr], simulatedData: "Paul Hudson\npaul@hackingwithswift.com", completion: handleScan)
            }
            .confirmationDialog("Sort By", isPresented: $showSortDialog) {
                Button {
                    sortBy = .name
                } label: {
                    Text("By Name")
                }
                
                Button {
                    sortBy = .creationDate
                } label: {
                    Text("By Date")
                }
            }
        }
    }
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }
    
    var sortedProspects: [Prospect] {
        var filteredProspects: [Prospect]
        
        switch filter {
        case .none:
            filteredProspects = prospects.people
        case .contacted:
            filteredProspects = prospects.people.filter { $0.isContacted }
        case .uncontacted:
            filteredProspects = prospects.people.filter { !$0.isContacted }
        }
        
        let sortedProspects = filteredProspects.sorted {
            switch sortBy {
            case .name:
                return $0.name < $1.name
            case .creationDate:
                return $0.creationDate < $1.creationDate
            }
        }
        return sortedProspects
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            
            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            prospects.add(person)
            
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default
            
            var dataComponents = DateComponents()
            dataComponents.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: dataComponents, repeats: false)
//            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else {
                        print("D'oh!")
                    }
                }
            }
        }
    }
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
            .environmentObject(Prospects())
    }
}
