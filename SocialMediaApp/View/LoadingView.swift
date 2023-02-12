//
//  LoadingView.swift
//  SocialMediaApp
//
//  Created by Deniz Ata Eş on 12.02.2023.
//

import SwiftUI

struct LoadingView: View {
    @Binding var show: Bool
    
    var body: some View {
        if show{
            ZStack{
                Group{
                    Rectangle()
                        .fill(.black.opacity(0.25))
                        .ignoresSafeArea()
                    ProgressView()
                        .padding(15)
                        .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: show)
        }
    }
}
