//
//  LoginView.swift
//  SocialMediaApp
//
//  Created by Deniz Ata Eş on 12.02.2023.
//

import SwiftUI
import PhotosUI
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

//MARK: Register View
struct RegisterView: View{
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilePicData: Data?
    
    //MARK: View Properties
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    
    //MARK: UserDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View{
        VStack(spacing: 10){
            Text("Lets Register\nAccount")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Hello user, have a wonderful journey")
                .font(.title3)
                .hAlign(.leading)
            
            // MARK: For Smaller Size Optimization
            ViewThatFits{
                ScrollView(.vertical, showsIndicators: false)
                {
                    HelperView()
                }
                
            HelperView()
            }
            
            
            
            
            // MARK: Register Button
            HStack{
                Text("Already Have an account?")
                    .foregroundColor(.gray)
                
                Button("Login Now"){
                    dismiss()
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
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { newValue in
            // MARK: Extracting UIImage from PhotoItem
            if let newValue{
                Task{
                    do{
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else{return}
                        // MARK: UI Must be updated on Main Thread
                        await MainActor.run(body: {
                            userProfilePicData = imageData
                        })
                    }catch{
                        
                    }
                }
            }
        }
        // MARK: Displaying Alert
        .alert(errorMessage, isPresented: $showError) {
        }
        
    }
    
    @ViewBuilder
    func HelperView() -> some View{
        VStack(spacing: 12){
            
            ZStack{
                if let userProfilePicData, let image = UIImage(data: userProfilePicData){
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                else{
                    Image(systemName: "person")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .padding(.top, 25)
            .onTapGesture {
                showImagePicker.toggle()
            }
            
            TextField("Username", text: $userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                .padding(.top, 25)
            
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                
            
            SecureField("Password", text: $password)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("About You", text: $userBio, axis: .vertical)
                .frame(minHeight: 100,alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Bio Link (Optional)", text: $userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))

            Button(action: registerUser) {
                // MARK: Register Button
                
                Text("Sign up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .disableWithOpacity(userName == "" || userBio == "" || emailID == "" || password == "" || userProfilePicData == nil)
            .padding(.top, 10)

        }
    }
    
    func registerUser(){
        isLoading = true
        closeKeyboard()
        Task{
            do{
                // Step 1: Creating Firebase accunt
               try await Auth.auth().createUser(withEmail: emailID, password: password)
                // Step 2: Uploading profile photo Into Firebase Storage
                guard let userUID = Auth.auth().currentUser?.uid else{
                    return
                }
                guard let imageData = userProfilePicData else{return}
                        let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                
                //Step 3: Downloading Photo URL
                let downloadURL = try await storageRef.downloadURL()
                
                //Step 4: Creating a User Firestore Object.
                let user = User(username: userName, userBio: userBio, userBioLink: userBioLink, userUID: userUID, userEmail: emailID, userProfileURL: downloadURL)
                
                //Step 5: Saving User Doc into Firestore Database
                
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: { error in
                    if error == nil{
                        // MARK: Print saved succesfully
                        print("Saved succesfully")
                        userNameStored = userName
                        self.userUID = userUID
                        profileURL = downloadURL
                        logStatus = true
                    }
                })
                
            }catch{
                //  MARK: Deleting Created Account In Case of Failure
                try await Auth.auth().currentUser?.delete()
                await setError(error)
            }
        }
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

extension View{
    
    // Closing All Active Keyboards
    func closeKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    //MARK: Disabling with Opacity
    func disableWithOpacity(_ condition: Bool) -> some View{
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1)
    }
    
    func hAlign(_ alignment: Alignment) -> some View{
        self
            .frame(maxWidth: .infinity, alignment: alignment)
            
        
    }
    
    func vAlign(_ alignment: Alignment) -> some View{
        self
            .frame(maxHeight: .infinity, alignment: alignment)
        
    }
    
    
    //MARK: Custom Border View Width Padding
    
    func border(_ width: CGFloat, _ color: Color) -> some View{
        
        self.padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(color, lineWidth: width)
            }
    }
    
    // MARK: Custom fill View With Padding
    func fillView(_ color: Color) -> some View{
        
        self.padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(color)
            }
    }
}
