//
//  ReusableProfileContent.swift
//  SocialMediaApp
//
//  Created by Deniz Ata Eş on 13.02.2023.
//

import SwiftUI
import SDWebImageSwiftUI

struct ReusableProfileContent: View {
    var user: User
    @State private var fetchedPosts: [Post] = []
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack{
                HStack(spacing: 12){
                    WebImage(url: user.userProfileURL).placeholder{
                        //MARK: PlaceHolder Image
                        Image(systemName: "person")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6){
                        Text(user.username)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(user.userBio)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(3)
                        
                        // MARK: Displaying Bio Link, If Given While Signing Up Profile Page
                        if let bioLink = URL(string: user.userBioLink){
                            Link(user.userBioLink, destination: bioLink)
                                .font(.callout)
                                .tint(.blue)
                                .lineLimit(1)
                            
                        }
                    }
                    .hAlign(.leading)
                }
                
                Text("Post's")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .hAlign(.leading)
                    .padding(.vertical,15)
                
                ReusablePostsView(basedOnUID: true, uid: user.userUID, posts: $fetchedPosts)
                  
            }
            .padding(15)
        }
    }
}
