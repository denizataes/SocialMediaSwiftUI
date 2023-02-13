//
//  ContentView.swift
//  SocialMediaApp
//
//  Created by Deniz Ata Eş on 12.02.2023.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    
    var body: some View {
        
        //MARK: Redirecting User Based on Log Status
        
        if logStatus{
            MainView()
        }
        else{
            LoginView()
        }
        
       
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
