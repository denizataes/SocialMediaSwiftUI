//
//  ProfileView.swift
//  SocialMediaApp
//
//  Created by Deniz Ata Eş on 13.02.2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
struct ProfileView: View {
    //MARK: My Profile Data
    @State private var myProfile: User?
    @AppStorage("log_status") var logStatus: Bool = false
    // MARK: View Properties Message
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    var body: some View {
        NavigationStack{
            VStack{
                if let myProfile{
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            // MARK: Refresh User Data
                            self.myProfile = nil
                            await fetchUserData()
                        }
                }else{
                    ProgressView()
                }
            }

            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu{
                        // MARK: Two Action's
                        // 1. Logout
                        // 2. Delete Account
                        Button("Logout",action: logOutUser)
                        Button("Delete Account", role: .destructive, action: deleteAccount)
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .overlay{
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError) {
        }
        .task {
            //This Modifier is like onAppear
            //So Fetching for the first time only
            if myProfile != nil{return}
            // MARK: Initial Fetch
            await fetchUserData()
        }
    }
    
    // MARK: Fetching User Data
    func fetchUserData()async{
        guard let userUID = Auth.auth().currentUser?.uid else {return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else { return }
        await MainActor.run(body: {
            myProfile = user
        })
    }
    //MARK: Logging User Out
    func logOutUser(){
        try? Auth.auth().signOut()
        logStatus = false
    }
    
    // MARK: Deleting User Entire Account
    func deleteAccount(){
        isLoading = true
        Task{
            do{
                guard let userUID = Auth.auth().currentUser?.uid else{return}
                // Step 1: First Deleting Profile Image From Storage
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                
                // Step 2: Deleting Firestore User Document
                try  await Firestore.firestore().collection("Users").document(userUID).delete()
                // Final Step: Deleting Auth account and Setting Log Status To False
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            }catch{
                await setError(error)
            }
            
        }
    }
    
    // MARK: Setting Error
    func setError(_ error: Error)async{
        // MARK: UI Must be run on Main Thread
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
