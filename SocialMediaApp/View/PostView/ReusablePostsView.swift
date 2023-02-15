//
//  ReusablePostsView.swift
//  SocialMediaApp
//
//  Created by Deniz Ata Eş on 14.02.2023.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore

struct ReusablePostsView: View {
    var basedOnUID: Bool = false
    var uid: String = ""
    @Binding var posts: [Post]
    /// - View Properties
    @State private var isFetching: Bool = true
    
    /// -Pagination
    @State private var paginationDoc: QueryDocumentSnapshot?
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack{
                if isFetching{
                    ProgressView()
                        .padding(.top, 30)
                }else{
                    if posts.isEmpty{
                        ///No Post's Found on Firestore
                        Text("No Post's Found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 30)
                    }else{
                        /// - Displaying Post's
                        Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            /// - Scroll to Refresh
            /// Disabling Refresh for UID based Post's
            guard !basedOnUID else{return}
            isFetching = true
            posts = []
            /// - Resetting Pagination Doc
            paginationDoc = nil
            await fetchPosts()
        }
        .task {
            /// - Fetching For One Time
            guard posts.isEmpty else{return}
            await fetchPosts()
        }
    }
    
    /// - Displaying Fetched Post's
    @ViewBuilder
    func Posts() -> some View{
        ForEach(posts){
            post in
            PostCardView(post: post) { updatedPost in
                /// Updating Post in the array
                if let index = posts.firstIndex(where: { post
                    in
                    post.id == updatedPost.id
                }){
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs = updatedPost.dislikedIDs
                }
            } onDelete: {
                /// Removing Post From The array
                withAnimation(.easeInOut(duration: 0.25)){
                    posts.removeAll { post.id == $0.id }
                }
            }
            .onAppear{
                /// - When Last Post Appears, Fetching New Post (If There)
                if post.id == posts.last?.id && paginationDoc != nil{
                    Task{ await fetchPosts() }
                }
            }
            
            Divider()
                .padding(.horizontal, -15)

        }
    }
    
    /// - Fetching Post's
    func fetchPosts()async{
        do{
            var query: Query!
            /// - Implementing Pagination
            if let paginationDoc{
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20)
            }else{
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 20)
            }
            
            /// - New Query For UID Based Document Fetch
            /// Simply filter the Post's Which is not belongs to this UID
            if basedOnUID{
                query = query
                    .whereField("userUID", isEqualTo: uid)
            }
     
            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap{ doc -> Post? in
                try? doc.data(as: Post.self)
            }
            await MainActor.run(body: {
                posts.append(contentsOf: fetchedPosts)
                paginationDoc = docs.documents.last
                isFetching = false
            })
        }catch{
            print(error.localizedDescription)
        }
    }
}

struct ReusablePostsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
