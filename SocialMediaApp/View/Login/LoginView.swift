//
//  LoginView.swift
//  SocialMediaApp
//
//  Created by Deniz Ata Eş on 12.02.2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct LoginView: View {
    //MARK: User Details
    
    @State var emailID: String = ""
    @State var password: String = ""
    
    // MARK: View Properties
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    //MARK: User Defaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    
    var body: some View {
        VStack(spacing: 10){
            Text("Lets Sign you in")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Welcome back.\n You have been missed")
                .font(.title3)
                .hAlign(.leading)
            
            VStack(spacing: 12){
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top, 25)
                
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                Button("Reset Password?", action: {resetPassword()})
                    .font(.callout)
                    .fontWeight(.medium)
                    .tint(.black)
                    .hAlign(.trailing)
                
                Button {
                    loginUser()
                } label: {
                    // MARK: Login Button
                    
                    Text("Sign in")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                .padding(.top, 10)

            }
            
            // MARK: Register Button
            
            
            HStack{
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                
                Button("Register Now"){
                    createAccount.toggle()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        //MARK: Register View VIA Sheets
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        
        // MARK: Displaying Alert
        .alert(errorMessage, isPresented: $showError) {
            
        }
    }
    
    func loginUser(){
        isLoading = true
        closeKeyboard()
        Task{
            do{
                // With the help of Swift Concurrency Auth can be done with Single line
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("User Found")
                try await fetchUser()
                
            }catch{
                await setError(error)
            }
        }
    }
    
    func resetPassword(){
        Task{
            do{
                // With the help of Swift Concurrency Auth can be done with Single line
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
                print("Link Sent")
       
                
            }catch{
                await setError(error)
                
            }
        }
    }
    
    // MARK: If user if found then fetching User Data From Firestore
    
    func fetchUser() async throws{
        guard let userID = Auth.auth().currentUser?.uid else {return}
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        //MARK: UI Updating must be run on main thread
        
        await MainActor.run(body: {
            // Setting UserDefaults data and Changing app's Auth Status
            userUID = userID
            userNameStored = user.username
            profileURL = user.userProfileURL
            logStatus = true
            
        })
    }

    // MARK: Displaying Error VIA Alert
    func setError(_ error: Error)async{
        // MARK: UI Must be updated on main thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
    
    
}



struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
//MARK: View Extension for UI Building

